describe CarnetDeBord::CreateCarnet, type: :service do
  subject do
    described_class.call(applicant:, agent:, department:)
  end

  let!(:applicant) do
    create(
      :applicant,
      address: "20 avenue ségur", nir:, department_internal_id: "ISJDAIJ", first_name: "John",
      last_name: "Doe", phone_number: "0620022002", email: "john@doe.com", affiliation_number: "AZDJZAID",
      birth_date:
    )
  end
  let!(:birth_date) { Time.zone.parse("20/11/2000").to_date }
  let!(:nir) { generate_random_nir }
  let!(:department) { create(:department, carnet_de_bord_deploiement_id:, number: "93") }
  let!(:carnet_de_bord_deploiement_id) { "382A2" }
  let!(:agent) { create(:agent, email: "someone@gouv.fr") }
  let!(:expected_payload) do
    {
      rdviUserEmail: "someone@gouv.fr",
      deploymentId: "382A2",
      notebook: {
        nir:,
        externalId: "ISJDAIJ",
        firstname: "John",
        lastname: "Doe",
        dateOfBirth: birth_date,
        mobileNumber: "+33620022002",
        email: "john@doe.com",
        cafNumber: "AZDJZAID",
        address1: "20 avenue de Ségur",
        postalCode: "75007",
        city: "Paris"
      }
    }
  end

  describe "#call" do
    before do
      allow(RetrieveGeolocalisation).to receive(:call).with(
        address: "20 avenue ségur", department_number: "93"
      ).and_return(OpenStruct.new(name: "20 avenue de Ségur", postcode: "75007", city: "Paris"))
      allow(CarnetDeBordClient).to receive(:create_carnet)
        .with(expected_payload)
        .and_return(OpenStruct.new(success?: true, body: { notebookId: "92119" }.to_json))
    end

    it "is a success" do
      is_a_success
    end

    it "assigns the carnet id" do
      subject
      expect(applicant.reload.carnet_de_bord_carnet_id).to eq("92119")
    end

    context "when the carnet creation fails" do
      before do
        allow(CarnetDeBordClient).to receive(:create_carnet)
          .with(expected_payload)
          .and_return(OpenStruct.new(success?: false, status: 401, body: { message: "Not authorized" }.to_json))
      end

      it "is a failure" do
        is_a_failure
      end

      it "returns an error" do
        expect(subject.errors).to eq(["Erreur en créant le carnet: Not authorized - 401"])
      end
    end

    context "when the department does not have a deploiement id" do
      before { department.update! carnet_de_bord_deploiement_id: nil }

      it "is a failure" do
        is_a_failure
      end

      it "returns an error" do
        expect(subject.errors).to eq(["le département 93 n'a pas d'ID de déploiement CdB"])
      end
    end

    context "when the applicant has a carnet id already assigned" do
      before { applicant.update! carnet_de_bord_carnet_id: "02012139" }

      it "is a failure" do
        is_a_failure
      end

      it "returns an error" do
        expect(subject.errors).to eq(["le carnet existe déjà pour la personne #{applicant.id}"])
      end
    end

    context "when the applicant does not have an adress" do
      before { applicant.update! address: nil }

      let!(:expected_payload) do
        {
          rdviUserEmail: "someone@gouv.fr",
          deploymentId: "382A2",
          notebook: {
            nir:,
            externalId: "ISJDAIJ",
            firstname: "John",
            lastname: "Doe",
            dateOfBirth: birth_date,
            mobileNumber: "+33620022002",
            email: "john@doe.com",
            cafNumber: "AZDJZAID"
          }
        }
      end

      it "creates the carnet without the payload" do
        expect(CarnetDeBordClient).to receive(:create_carnet).with(expected_payload)
        subject
      end

      it "is a success" do
        is_a_success
      end
    end

    context "when the geolocalisation retrieval fails" do
      before do
        allow(RetrieveGeolocalisation).to receive(:call).with(
          address: "20 avenue ségur", department_number: "93"
        ).and_return(OpenStruct.new(failure?: true))
      end

      let!(:expected_payload) do
        {
          rdviUserEmail: "someone@gouv.fr",
          deploymentId: "382A2",
          notebook: {
            nir:,
            externalId: "ISJDAIJ",
            firstname: "John",
            lastname: "Doe",
            dateOfBirth: birth_date,
            mobileNumber: "+33620022002",
            email: "john@doe.com",
            cafNumber: "AZDJZAID"
          }
        }
      end

      it "creates the carnet without the payload" do
        expect(CarnetDeBordClient).to receive(:create_carnet).with(expected_payload)
        subject
      end

      it "is a success" do
        is_a_success
      end
    end
  end
end
