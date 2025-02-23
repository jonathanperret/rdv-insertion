# rubocop:disable Metrics/ClassLength
class Applicant < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [
    :first_name, :last_name, :birth_date, :email, :phone_number, :address, :affiliation_number, :birth_name
  ].freeze
  RDV_SOLIDARITES_CLASS_NAME = "User".freeze
  REQUIRED_ATTRIBUTES_FOR_INVITATION_FORMATS = {
    "sms" => :phone_number,
    "email" => :email,
    "postal" => :address
  }.freeze
  SEARCH_ATTRIBUTES = [:first_name, :last_name, :affiliation_number, :email, :phone_number].freeze

  include Searchable
  include Notificable
  include PhoneNumberValidation
  include Invitable
  include HasParticipationsToRdvs
  include Applicant::TextHelper
  include Applicant::Address
  include Applicant::Nir
  include Applicant::Archivable

  attr_accessor :skip_uniqueness_validations

  before_validation :generate_uid
  before_save :format_phone_number

  has_many :rdv_contexts, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :archives, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy
  has_many :tag_applicants, dependent: :destroy
  has_many :applicants_organisations, dependent: :destroy

  has_many :rdvs, through: :participations
  has_many :organisations, through: :applicants_organisations
  has_many :notifications, through: :participations
  has_many :configurations, through: :organisations
  has_many :motif_categories, through: :rdv_contexts
  has_many :departments, through: :organisations
  has_many :referents, through: :referent_assignations, source: :agent
  has_many :tags, through: :tag_applicants

  accepts_nested_attributes_for :rdv_contexts, reject_if: :rdv_context_category_handled_already?
  accepts_nested_attributes_for :tag_applicants

  validates :last_name, :first_name, presence: true
  validates :email, allow_blank: true, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ }
  validate :birth_date_validity
  validates :rdv_solidarites_user_id, :nir, :pole_emploi_id,
            uniqueness: true, allow_nil: true, unless: :skip_uniqueness_validations

  delegate :name, :number, to: :department, prefix: true

  enum role: { demandeur: 0, conjoint: 1 }
  enum title: { monsieur: 0, madame: 1 }
  enum created_through: { rdv_insertion: 0, rdv_solidarites: 1 }, _prefix: true

  scope :active, -> { where(deleted_at: nil) }
  scope :without_rdv_contexts, lambda { |motif_categories|
    where.not(id: joins(:rdv_contexts).where(rdv_contexts: { motif_category: motif_categories }).ids)
  }
  scope :with_sent_invitations, -> { joins(:invitations).where.not(invitations: { sent_at: nil }).distinct }

  def rdv_seen_delay_in_days
    return if first_seen_rdv_starts_at.blank?

    first_seen_rdv_starts_at.to_datetime.mjd - created_at.to_datetime.mjd
  end

  def participation_for(rdv)
    participations.to_a.find { |participation| participation.rdv_id == rdv.id }
  end

  def organisations_with_rdvs
    organisations.where(id: rdvs.pluck(:organisation_id))
  end

  def delete_organisation(organisation)
    organisations.delete(organisation)
  end

  def rdv_context_for(motif_category)
    rdv_contexts.to_a.find { |rc| rc.motif_category_id == motif_category.id }
  end

  def deleted?
    deleted_at.present?
  end

  def can_be_invited_through?(invitation_format)
    send(REQUIRED_ATTRIBUTES_FOR_INVITATION_FORMATS[invitation_format]).present?
  end

  def soft_delete
    update_columns(
      deleted_at: Time.zone.now,
      affiliation_number: nil,
      role: nil,
      uid: nil,
      department_internal_id: nil,
      pole_emploi_id: nil,
      nir: nil,
      email: nil,
      phone_number: nil
    )
  end

  def assign_motif_category(motif_category_id)
    assign_attributes(rdv_contexts_attributes: [{ motif_category_id: motif_category_id }])
  end

  def as_json(...)
    super.deep_symbolize_keys
         .except(:last_webhook_update_received_at, :deleted_at, :rdv_solidarites_user_id)
         .merge(
           invitations: invitations.select(&:sent_at?),
           organisations: organisations,
           rdv_contexts: rdv_contexts,
           referents: referents,
           archives: archives,
           tags: tags
         )
  end

  def phone_number_formatted
    PhoneNumberHelper.format_phone_number(phone_number)
  end

  def carnet_de_bord_carnet_url
    "#{ENV['CARNET_DE_BORD_URL']}/manager/carnets/#{carnet_de_bord_carnet_id}"
  end

  private

  def rdv_context_category_handled_already?(rdv_context_attributes)
    rdv_context_attributes.deep_symbolize_keys[:motif_category_id]&.to_i.in?(motif_categories.map(&:id))
  end

  def generate_uid
    return if deleted?
    return if affiliation_number.blank? || role.blank?

    self.uid = Base64.strict_encode64("#{affiliation_number} - #{role}")
  end

  def format_phone_number
    self.phone_number = phone_number_formatted
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Time.zone.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "n'est pas valide")
  end
end

# rubocop: enable Metrics/ClassLength
