describe Applicants::RemoveReferent, type: :service do
  subject do
    described_class.call(
      agent: agent,
      applicant: applicant,
      rdv_solidarites_session: rdv_solidarites_session
    )
  end

  let!(:agent) { create(:agent) }
  let!(:applicant) { create(:applicant, referents: [agent]) }
  let!(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession::Base) }

  describe "#call" do
    before do
      allow(RdvSolidaritesApi::DeleteReferentAssignation).to receive(:call)
        .with(
          user_id: applicant.rdv_solidarites_user_id,
          agent_id: agent.rdv_solidarites_agent_id,
          rdv_solidarites_session: rdv_solidarites_session
        ).and_return(OpenStruct.new(success?: true))
    end

    it "is a success" do
      is_a_success
    end

    it "removes the agent from the applicant" do
      subject
      expect(applicant.reload.referents).to eq([])
    end

    context "when it fails to remove referent through API" do
      before do
        allow(RdvSolidaritesApi::DeleteReferentAssignation).to receive(:call)
          .with(
            user_id: applicant.rdv_solidarites_user_id,
            agent_id: agent.rdv_solidarites_agent_id,
            rdv_solidarites_session: rdv_solidarites_session
          ).and_return(OpenStruct.new(success?: false, errors: ["impossible to remove"]))
      end

      it "is a failure" do
        is_a_failure
      end

      it "does not remove the agent to the applicant" do
        subject
        expect(applicant.reload.referents).to include(agent)
      end

      it "outputs an error" do
        expect(subject.errors).to eq(["impossible to remove"])
      end
    end
  end
end
