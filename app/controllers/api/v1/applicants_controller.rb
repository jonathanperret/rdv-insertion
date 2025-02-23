module Api
  module V1
    class ApplicantsController < ApplicationController
      before_action :set_applicants_params, :set_organisation
      include ParamsValidationConcern

      def create_and_invite_many
        if @params_validation_errors.blank?

          applicants_attributes.each do |attrs|
            CreateAndInviteApplicantJob.perform_async(
              @organisation.id, attrs.except(:invitation), attrs[:invitation], rdv_solidarites_session.to_h
            )
          end

          render json: { success: true }
        else
          render json: { success: false, errors: @params_validation_errors }, status: :unprocessable_entity
        end
      end

      private

      def applicants_attributes
        create_and_invite_params.to_h.deep_symbolize_keys[:applicants].map do |applicant_attributes|
          applicant_attributes[:invitation] ||= {}
          applicant_attributes
        end
      end

      def invitations_attributes
        applicants_attributes.pluck(:invitation)
      end

      def set_organisation
        @organisation = Organisation.find_by!(rdv_solidarites_organisation_id: params[:rdv_solidarites_organisation_id])
        authorize @organisation, :create_and_invite_applicants?
      end

      def create_and_invite_params
        params.require(:applicants)
        params.permit(
          applicants: [
            :first_name, :last_name, :title, :affiliation_number, :role, :email, :phone_number,
            :nir, :pole_emploi_id,
            :birth_date, :rights_opening_date, :address, :department_internal_id, {
              invitation: [:rdv_solidarites_lieu_id, :motif_category_name]
            }
          ]
        )
      end

      def set_applicants_params
        # we want POST users/create_and_invite_many to behave like applicants/create_and_invite_many,
        # so we're changing the payload to have applicants instead of users
        params[:applicants] ||= params[:users]
      end
    end
  end
end
