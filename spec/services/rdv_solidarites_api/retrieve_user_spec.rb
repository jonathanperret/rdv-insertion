describe RdvSolidaritesApi::RetrieveUser, type: :service do
  subject do
    described_class.call(
      rdv_solidarites_session: rdv_solidarites_session,
      rdv_solidarites_user_id: rdv_solidarites_user_id
    )
  end

  let!(:rdv_solidarites_user_id) { 27 }
  let!(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession::Base) }
  let!(:rdv_solidarites_client) { instance_double(RdvSolidaritesClient) }

  describe "#call" do
    let!(:user) do
      { "id" => 5, "first_name" => "Dimitri", "last_name" => "Payet", "phone_number" => "+33782122222" }
    end

    before do
      allow(rdv_solidarites_session).to receive(:rdv_solidarites_client)
        .and_return(rdv_solidarites_client)
      allow(rdv_solidarites_client).to receive(:get_user)
        .and_return(OpenStruct.new(success?: true, body: { "user" => user }.to_json))
    end

    context "when it succeeds" do
      it("is a success") { is_a_success }

      it "retrieves the user" do
        expect(rdv_solidarites_client).to receive(:get_user)
          .with(rdv_solidarites_user_id)
        subject
      end

      it "returns the user" do
        expect(subject.user).to be_an_instance_of(RdvSolidarites::User)
        expect(subject.user.id).to eq(5)
        expect(subject.user.phone_number).to eq("+33782122222")
      end
    end

    context "when it fails" do
      before do
        allow(rdv_solidarites_client).to receive(:get_user)
          .and_return(OpenStruct.new(success?: false, body: { error_messages: ["some error"] }.to_json))
      end

      it("is a failure") { is_a_failure }

      it "returns the error" do
        expect(subject.errors).to eq(["Erreur RDV-Solidarités: some error"])
      end
    end
  end
end
