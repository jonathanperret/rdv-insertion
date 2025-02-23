class SoftDeleteApplicantJob < ApplicationJob
  def perform(rdv_solidarites_user_id)
    applicant = Applicant.find_by(rdv_solidarites_user_id: rdv_solidarites_user_id)
    return if applicant.blank? || applicant.deleted?

    applicant.soft_delete
    MattermostClient.send_to_notif_channel(
      "RDV Solidarites user #{rdv_solidarites_user_id} deleted"
    )
  end
end
