module Organisations
  class ApplicantAddedNotificationsController < ApplicationController
    def create
      OrganisationMailer.applicant_added(
        to: email_params[:to], subject: email_params[:subject], content: email_params[:content],
        applicant_attachements: email_params[:attachments] || [], reply_to: current_agent.email
      ).deliver_now
      flash.now[:success] = "L'email a bien été envoyé à l'organisation"
    end

    private

    def email_params
      params[:email]
    end
  end
end
