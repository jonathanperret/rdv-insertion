describe Applicants::Validate, type: :service do
  subject do
    described_class.call(applicant: applicant)
  end

  let!(:applicant) do
    create(
      :applicant,
      first_name: "Ramses",
      email: "ramses2@caramail.com",
      phone_number: "+33782605941",
      affiliation_number: "444222",
      role: "demandeur",
      department_internal_id: "ABBA",
      organisations: [organisation]
    )
  end
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }

  describe "#call" do
    context "when it is valid" do
      it("is a success") { is_a_success }
    end

    context "when an applicant has no identifier" do
      let!(:applicant) do
        create(
          :applicant,
          department_internal_id: nil, nir: nil, affiliation_number: nil, phone_number: nil, email: nil
        )
      end

      it("is a failure") { is_a_failure }

      it "returns an error" do
        expect(subject.errors).to include(
          "Il doit y avoir au moins un attribut permettant d'identifier la personne " \
          "(NIR, email, numéro de tel, ID interne, numéro d'allocataire/rôle)"
        )
      end
    end

    context "when an applicant shares the same department internal id" do
      let!(:other_applicant) do
        create(
          :applicant, id: 1395, department_internal_id: "ABBA", organisations: [other_org]
        )
      end

      context "inside the department" do
        let!(:other_org) { create(:organisation, department: department) }

        it("is a failure") { is_a_failure }

        it "returns an error" do
          expect(subject.errors).to include(
            "Un allocataire avec le même ID interne au département se trouve au sein du département: [1395]"
          )
        end
      end

      context "outside the department" do
        let!(:other_org) { create(:organisation, department: create(:department)) }

        it("is a success") { is_a_success }
      end
    end

    context "when an applicant shares the same uid" do
      let!(:other_applicant) do
        create(
          :applicant, id: 1395, affiliation_number: "444222", role: "demandeur", organisations: [other_org]
        )
      end

      context "inside the department" do
        let!(:other_org) { create(:organisation, department: department) }

        it("is a failure") { is_a_failure }

        it "returns an error" do
          expect(subject.errors).to include(
            "Un allocataire avec le même numéro d'allocataire et rôle se trouve au sein du département: [1395]"
          )
        end
      end

      context "outside the department" do
        let!(:other_org) { create(:organisation, department: create(:department)) }

        it("is a success") { is_a_success }
      end
    end

    context "when an applicant shares the same email" do
      context "with the same first name" do
        let!(:other_applicant) do
          create(:applicant, id: 1395, first_name: "ramses", email: "ramses2@caramail.com")
        end

        it("is a failure") { is_a_failure }

        it "returns an error" do
          expect(subject.errors).to include(
            "Un allocataire avec le même email et même prénom est déjà enregistré: [1395]"
          )
        end
      end

      context "with a different first name" do
        let!(:other_applicant) do
          create(:applicant, id: 1395, first_name: "toutankhamon", email: "ramses2@caramail.com")
        end

        it("is a success") { is_a_success }
      end
    end

    context "when an applicant shares the same phone number" do
      context "with the same first name" do
        let!(:other_applicant) do
          create(:applicant, id: 1395, first_name: "ramses", phone_number: "0782605941")
        end

        it("is a failure") { is_a_failure }

        it "returns an error" do
          expect(subject.errors).to include(
            "Un allocataire avec le même numéro de téléphone et même prénom est déjà enregistré: [1395]"
          )
        end
      end

      context "with a different first name" do
        let!(:other_applicant) do
          create(:applicant, id: 1395, first_name: "toutankhamon", phone_number: "0782605941")
        end

        it("is a success") { is_a_success }
      end
    end
  end
end
