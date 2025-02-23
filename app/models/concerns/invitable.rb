module Invitable
  extend ActiveSupport::Concern

  def sent_invitations
    invitations.to_a.select(&:sent_at?)
  end

  def first_sent_invitation
    sent_invitations.min_by(&:sent_at)
  end

  def first_invitation_sent_at
    first_sent_invitation&.sent_at
  end

  def first_sent_invitation_after_last_participation
    sent_invitations.select { |invitation| invitation.sent_at > last_created_participation.created_at }
                    .min_by(&:sent_at)
  end

  def first_sent_invitation_after_last_participation_by(format)
    sent_invitations.select do |invitation|
      invitation.format == format && invitation.sent_at > last_created_participation.created_at
    end.min_by(&:sent_at)
  end

  def last_sent_invitation
    sent_invitations.max_by(&:sent_at)
  end

  def last_invitation_sent_at
    last_sent_invitation&.sent_at
  end

  def first_sent_invitation_by(format)
    sent_invitations.select { |invitation| invitation.format == format }.min_by(&:sent_at)
  end

  def invited_through?(format)
    sent_invitations.any? { |invitation| invitation.format == format }
  end

  def first_invitation_relative_to_last_participation
    participations.any? ? first_sent_invitation_after_last_participation : first_sent_invitation
  end

  def first_invitation_relative_to_last_participation_by(format)
    participations.any? ? first_sent_invitation_after_last_participation_by(format) : first_sent_invitation_by(format)
  end

  def first_invitation_relative_to_last_participation_sent_at
    first_invitation_relative_to_last_participation&.sent_at
  end

  def first_invitation_relative_to_last_participation_sent_at_by(format)
    first_invitation_relative_to_last_participation_by(format)&.sent_at
  end

  def last_invitation_sent_manually
    sent_invitations.reject(&:reminder?).max_by(&:sent_at)
  end

  def invited_before_time_window?(number_of_days_before_action_required)
    last_invitation_sent_manually.present? &&
      last_invitation_sent_manually.sent_at < number_of_days_before_action_required.days.ago
  end

  def invalidate_invitations
    invitations.each do |invitation|
      InvalidateInvitationJob.perform_async(invitation.id)
    end
  end
end
