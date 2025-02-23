describe ReferentAssignationsController do
  let!(:applicant_id) { 2222 }
  let!(:applicant) do
    create(:applicant, id: applicant_id, organisations: [organisation1, organisation2])
  end
  let!(:organisation1) { create(:organisation, name: "CD de DIE") }
  let!(:organisation2) { create(:organisation, name: "CD de Valence") }
  let!(:organisation3) { create(:organisation) }
  let!(:department) { create(:department, organisations: [organisation1, organisation2, organisation3]) }
  let!(:agent1) do
    create(
      :agent,
      organisations: [organisation1], first_name: "Bernard", last_name: "Lama", email: "bernardlama@france98.fr"
    )
  end
  let!(:agent2) do
    create(
      :agent,
      organisations: [organisation2], first_name: "Lionel", last_name: "Charbonnier",
      email: "lionelcharbonnier@france98.fr"
    )
  end
  let!(:agent3) do
    create(
      :agent,
      organisations: [organisation3], first_name: "Fabien", last_name: "Barthez"
    )
  end

  let!(:agent) { create(:agent, organisations: [organisation1]) }

  render_views

  before do
    sign_in(agent)
  end

  describe "#index" do
    before { applicant.update!(referents: [agent2]) }

    it "shows the agents that can be assigned/removed" do
      get :index, params: { applicant_id: applicant_id, department_id: department.id }

      expect(response).to be_successful
      expect(response.body).to match(/Bernard Lama \(bernardlama@france98.fr\)/)
      expect(response.body).to match(/Lionel Charbonnier \(lionelcharbonnier@france98.fr\)/)
      expect(response.body).to match(/Assigner/)
      expect(response.body).to match(/Retirer/)
      expect(response.body).not_to match(/Fabien Barthez/)
    end
  end

  describe "#create" do
    subject do
      post :create, params: create_params
    end

    let!(:create_params) do
      {
        department_id: department.id, referent_assignation: { applicant_id: applicant.id, agent_id: agent2.id },
        format: "turbo_stream"
      }
    end

    before do
      allow(Applicants::AssignReferent).to receive(:call)
        .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)
        .and_return(OpenStruct.new(success?: true))
    end

    it "assigns the agent with a success message" do
      subject

      expect(response).to be_successful
      expect(response.body).to match(/flashes/)
      expect(response.body).to match(/Le référent a bien été assigné/)
    end

    context "when the assignation fails" do
      before do
        allow(Applicants::AssignReferent).to receive(:call)
          .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)
          .and_return(OpenStruct.new(success?: false, errors: ["Something wrong happened"]))
      end

      it "assigns the agent with a success message" do
        subject

        expect(response).to be_successful
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Something wrong happened/)
        expect(unescaped_response_body).to match(/Une erreur s'est produite lors de l'assignation du référent/)
      end
    end

    context "when the agent email is passed and the request is JSON" do
      let!(:create_params) do
        {
          department_id: department.id, referent_assignation: { applicant_id: applicant.id, agent_email: agent2.email },
          format: "json"
        }
      end

      before do
        allow(Applicants::AssignReferent).to receive(:call)
          .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)
          .and_return(OpenStruct.new(success?: true))
      end

      it "assigns the agent with a success message" do
        expect(Applicants::AssignReferent).to receive(:call)
          .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)

        subject

        expect(response).to be_successful
        expect(parsed_response_body["success"]).to eq(true)
      end
    end
  end

  describe "#destroy" do
    subject do
      post :destroy, params: {
        applicant_id: applicant_id, department_id: department.id, referent_assignation: {
          agent_id: agent2.id
        }, format: "turbo_stream"
      }
    end

    before do
      allow(Applicants::RemoveReferent).to receive(:call)
        .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)
        .and_return(OpenStruct.new(success?: true))
    end

    it "assigns the agent with a success message" do
      subject

      expect(response).to be_successful
      expect(unescaped_response_body).to match(/flashes/)
      expect(unescaped_response_body).to match(/Le référent a bien été retiré/)
    end

    context "when the assignation fails" do
      before do
        allow(Applicants::RemoveReferent).to receive(:call)
          .with(applicant: applicant, agent: agent2, rdv_solidarites_session: rdv_solidarites_session)
          .and_return(OpenStruct.new(success?: false, errors: ["Something wrong happened"]))
      end

      it "assigns the agent with a success message" do
        subject

        expect(response).to be_successful
        expect(unescaped_response_body).to match(/flashes/)
        expect(unescaped_response_body).to match(/Something wrong happened/)
        expect(unescaped_response_body).to match(/Une erreur s'est produite lors du détachement du référent/)
      end
    end
  end
end
