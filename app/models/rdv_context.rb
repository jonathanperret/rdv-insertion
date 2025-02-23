class RdvContext < ApplicationRecord
  include RdvContextStatus
  include Invitable
  include Notificable
  include HasParticipationsToRdvs

  belongs_to :applicant
  belongs_to :motif_category
  has_many :invitations, dependent: :destroy
  has_many :participations, dependent: :nullify

  has_many :rdvs, through: :participations
  has_many :notifications, through: :participations

  validates :applicant, uniqueness: { scope: :motif_category,
                                      message: "est déjà suivi pour cette catégorie de motif" }

  delegate :position, :name, :short_name, to: :motif_category, prefix: true

  STATUSES_WITH_ACTION_REQUIRED = %w[
    rdv_needs_status_update rdv_noshow rdv_revoked rdv_excused multiple_rdvs_cancelled
  ].freeze
  CONVOCABLE_STATUSES = %w[
    rdv_noshow rdv_excused multiple_rdvs_cancelled
  ].freeze

  scope :status, ->(status) { where(status: status) }
  scope :action_required, lambda { |number_of_days_before_action_required|
    status(STATUSES_WITH_ACTION_REQUIRED)
      .or(invitation_pending.invited_before_time_window(number_of_days_before_action_required))
  }
  scope :invited_before_time_window, lambda { |number_of_days_before_action_required|
    where.not(
      id: joins(:invitations).where("invitations.sent_at > ?", number_of_days_before_action_required.days.ago)
                             .where(invitations: { reminder: false })
                             .pluck(:rdv_context_id)
    )
  }
  scope :with_sent_invitations, -> { joins(:invitations).where.not(invitations: { sent_at: nil }) }

  def action_required_status?
    status.in?(STATUSES_WITH_ACTION_REQUIRED)
  end

  def convocable_status?
    status.in?(CONVOCABLE_STATUSES)
  end

  def time_to_accept_invitation_exceeded?(number_of_days_before_action_required)
    invitation_pending? && invited_before_time_window?(number_of_days_before_action_required)
  end

  def time_between_invitation_and_rdv_in_days
    first_participation_creation_date.to_datetime.mjd - first_invitation_sent_at.to_datetime.mjd
  end

  def as_json(...)
    super.merge(
      human_status: I18n.t("activerecord.attributes.rdv_context.statuses.#{status}"),
      participations: participations
    )
  end
end
