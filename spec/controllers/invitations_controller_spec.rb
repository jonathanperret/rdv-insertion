describe InvitationsController do
  describe "#create" do
    let!(:applicant_id) { "24" }
    let!(:organisation_id) { "22" }
    let!(:help_phone_number) { "0101010101" }
    let!(:department) { create(:department) }
    let!(:organisation) { create(:organisation, id: organisation_id, department: department) }
    let!(:configuration) do
      create(
        :configuration,
        organisation: organisation, number_of_days_before_action_required: 10,
        motif_category: motif_category, rdv_with_referents: false, invite_to_applicant_organisations_only: false
      )
    end
    let!(:other_org) { create(:organisation, department: department) }

    let!(:organisations) { Organisation.where(id: organisation.id) }
    let!(:agent) { create(:agent, organisations: organisations) }
    let!(:applicant) do
      create(
        :applicant,
        first_name: "JANE", last_name: "DOE", title: "madame",
        id: applicant_id, organisations: [organisation]
      )
    end
    let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation") }

    let!(:create_params) do
      {
        organisation_id: organisation.id,
        applicant_id: applicant_id,
        invitation_format: "sms",
        help_phone_number: help_phone_number,
        motif_category_id: motif_category.id,
        format: "json"
      }
    end
    let!(:invitation) do
      create(
        :invitation,
        applicant: applicant, department: department, organisations: organisations,
        help_phone_number: help_phone_number, rdv_context: rdv_context
      )
    end

    let!(:rdv_context) { build(:rdv_context, applicant: applicant, motif_category: motif_category) }
    let!(:valid_until) { Time.zone.parse("2022-05-14 12:30") }

    before do
      sign_in(agent)
      travel_to(Time.zone.parse("2022-05-04 12:30"))
      allow(RdvContext).to receive(:find_or_create_by!)
        .with(motif_category: motif_category, applicant: applicant)
        .and_return(rdv_context)
      allow(Invitation).to receive(:new)
        .with(
          department: department, applicant: applicant, organisations: organisations, rdv_context: rdv_context,
          help_phone_number: help_phone_number,
          format: "sms", rdv_solidarites_lieu_id: nil, valid_until: valid_until,
          rdv_with_referents: false
        ).and_return(invitation)
      allow(Invitations::SaveAndSend).to receive(:call)
        .with(invitation: invitation, rdv_solidarites_session: rdv_solidarites_session)
        .and_return(OpenStruct.new(success?: true))
    end

    context "organisation level" do
      it "finds or create a context" do
        expect(RdvContext).to receive(:find_or_create_by!)
          .with(motif_category: motif_category, applicant: applicant)
        post :create, params: create_params
      end

      it "instantiate the invitation" do
        expect(Invitation).to receive(:new)
          .with(
            department: department, applicant: applicant, organisations: organisations, rdv_context: rdv_context,
            help_phone_number: help_phone_number,
            format: "sms", rdv_solidarites_lieu_id: nil,
            valid_until: valid_until, rdv_with_referents: false
          )
        post :create, params: create_params
      end

      it "calls the service" do
        expect(Invitations::SaveAndSend).to receive(:call)
          .with(
            invitation: invitation,
            rdv_solidarites_session: rdv_solidarites_session
          )
        post :create, params: create_params
      end
    end

    context "department level" do
      let!(:organisations) { Organisation.where(id: [organisation.id, other_org.id]) }
      let!(:create_params) do
        {
          department_id: department.id,
          applicant_id: applicant_id,
          invitation_format: "email",
          help_phone_number: help_phone_number,
          motif_category_id: motif_category.id,
          rdv_solidarites_lieu_id: "3929",
          format: "json"
        }
      end

      before do
        allow(Invitation).to receive(:new)
          .with(
            department: department, applicant: applicant, organisations: organisations, rdv_context: rdv_context,
            help_phone_number: help_phone_number,
            format: "email", rdv_solidarites_lieu_id: "3929",
            valid_until: valid_until, rdv_with_referents: false
          ).and_return(invitation)
      end

      it "finds or create a context" do
        expect(RdvContext).to receive(:find_or_create_by!)
          .with(motif_category: motif_category, applicant: applicant)
        post :create, params: create_params
      end

      it "instantiate the invitation" do
        expect(Invitation).to receive(:new)
          .with(
            department: department, applicant: applicant, organisations: organisations, rdv_context: rdv_context,
            format: "email", help_phone_number: help_phone_number,
            rdv_solidarites_lieu_id: "3929", valid_until: valid_until, rdv_with_referents: false
          )
        post :create, params: create_params
      end

      it "calls the service" do
        expect(Invitations::SaveAndSend).to receive(:call)
          .with(
            invitation: invitation,
            rdv_solidarites_session: rdv_solidarites_session
          )
        post :create, params: create_params
      end

      context "when the config invites to applicants organisations only" do
        before do
          configuration.update!(invite_to_applicant_organisations_only: true)
          allow(Invitation).to receive(:new)
            .with(
              department: department, applicant: applicant, organisations: [organisation], rdv_context: rdv_context,
              help_phone_number: help_phone_number,
              format: "email", rdv_solidarites_lieu_id: "3929",
              valid_until: valid_until, rdv_with_referents: false
            ).and_return(invitation)
        end

        it "instantiates the invitation with the applicant orgs only" do
          expect(Invitation).to receive(:new)
            .with(
              department: department, applicant: applicant, organisations: [organisation], rdv_context: rdv_context,
              format: "email", help_phone_number: help_phone_number,
              rdv_solidarites_lieu_id: "3929", valid_until: valid_until, rdv_with_referents: false
            )
          post :create, params: create_params
        end
      end
    end

    context "when the service succeeds" do
      context "when sms or email invitation" do
        it "is a success" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.parsed_body["success"]).to eq(true)
        end

        it "renders the invitation" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.parsed_body["invitation"]["id"]).to eq(invitation.id)
        end
      end

      context "when postal invitation" do
        let!(:invitation) do
          create(
            :invitation,
            applicant: applicant, department: department, organisations: organisations,
            help_phone_number: help_phone_number, format: "postal"
          )
        end
        let!(:create_params) do
          {
            organisation_id: organisation.id,
            applicant_id: applicant_id,
            invitation_format: "postal",
            help_phone_number: help_phone_number,
            motif_category_id: motif_category.id,
            format: "pdf"
          }
        end

        before do
          allow(Invitation).to receive(:new)
            .with(
              department: department, applicant: applicant, organisations: organisations, rdv_context: rdv_context,
              format: "postal", help_phone_number: help_phone_number,
              rdv_solidarites_lieu_id: nil, valid_until: valid_until, rdv_with_referents: false
            ).and_return(invitation)
          allow(WickedPdf).to receive_message_chain(:new, :pdf_from_string)
          allow(Invitations::SaveAndSend).to receive(:call)
            .with(invitation: invitation, rdv_solidarites_session: rdv_solidarites_session)
            .and_return(OpenStruct.new(success?: true))
          allow(invitation).to receive(:content).and_return("some content")
        end

        it "is a success" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.headers["Content-Type"]).to eq("application/pdf")
        end

        it "renders the invitation" do
          post :create, params: create_params
          expect(response).to be_successful
          expect(response.headers["Content-Disposition"]).to start_with("attachment; filename=")
          first_name = applicant.first_name
          last_name = applicant.last_name
          expect(response.headers["Content-Disposition"]).to end_with("_#{last_name}_#{first_name}.pdf")
        end
      end
    end

    context "when the service fails" do
      before do
        allow(Invitations::SaveAndSend).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["some error"]))
      end

      it "is not a success" do
        post :create, params: create_params
        expect(response).not_to be_successful
        expect(response.parsed_body["success"]).to eq(false)
      end

      it "renders the errors" do
        post :create, params: create_params
        expect(response).not_to be_successful
        expect(response.parsed_body["errors"]).to eq(["some error"])
      end
    end
  end

  describe "GET #invitation_code" do
    render_views

    it "returns a success response" do
      get :invitation_code
      expect(response).to be_successful
      expect(response.body).to match(/Je prends rendez-vous/)
    end
  end

  describe "#redirect" do
    subject { get :redirect, params: invite_params }

    let!(:applicant_id) { "24" }
    let!(:invitation) { create(:invitation, format: "sms") }
    let!(:invitation2) { create(:invitation, format: "email") }

    context "when uuid is passed" do
      let!(:invite_params) { { uuid: invitation2.uuid } }

      it "redirects to the invitation link" do
        subject
        expect(response).to redirect_to invitation2.link
      end

      context "when the invitation is no longer valid" do
        render_views
        before { invitation2.update!(valid_until: 2.days.ago) }

        it "says the invitation is invalid" do
          subject
          expect(response.body.encode).to include("Désolé, votre invitation n'est plus valide !")
          expect(response.body.encode).to include(invitation.help_phone_number)
        end
      end

      context "when the uuid cannot be found" do
        let!(:invite_params) { { uuid: "some_wrong_uuid" } }

        it "redirects back to the invitation page" do
          subject
          expect(response).to redirect_to :invitation_landing
        end

        it "displays an error message" do
          subject
          expect(flash[:error]).not_to be_nil
        end
      end
    end
  end
end
