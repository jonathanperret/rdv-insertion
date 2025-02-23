describe Exporters::GenerateApplicantsCsv, type: :service do
  subject { described_class.call(applicants: applicants, structure: structure, motif_category: motif_category) }

  let!(:now) { Time.zone.parse("22/06/2022") }
  let!(:timestamp) { now.to_i }
  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation") }
  let!(:department) { create(:department, name: "Drôme", number: "26") }
  let!(:organisation) { create(:organisation, name: "Drome RSA", department: department) }
  let!(:structure) { organisation }
  let!(:configuration) { create(:configuration, organisation: organisation, motif_category: motif_category) }
  let!(:nir) { generate_random_nir }
  let!(:applicant1) do
    create(
      :applicant,
      first_name: "Jane",
      last_name: "Doe",
      title: "madame",
      affiliation_number: "12345",
      department_internal_id: "33333",
      nir: nir,
      pole_emploi_id: "DDAAZZ",
      email: "jane@doe.com",
      address: "20 avenue de Ségur 75OO7 Paris",
      phone_number: "+33610101010",
      birth_date: "20/12/1977",
      rights_opening_date: "18/05/2022",
      created_at: "20/05/2022",
      role: "demandeur",
      organisations: [organisation],
      referents: [referent]
    )
  end
  let(:applicant2) { create(:applicant, last_name: "Casubolo", organisations: [organisation]) }
  let(:applicant3) { create(:applicant, last_name: "Blanc", organisations: [organisation]) }

  let!(:rdv) do
    create(:rdv, starts_at: Time.zone.parse("2022-05-25"),
                 created_by: "user",
                 participations: [participation_rdv])
  end
  let!(:participation_rdv) { create(:participation, applicant: applicant1, status: "seen") }

  let!(:first_invitation) do
    create(:invitation, applicant: applicant1, format: "email", sent_at: Time.zone.parse("2022-05-21"))
  end
  let!(:last_invitation) do
    create(:invitation, applicant: applicant1, format: "email", sent_at: Time.zone.parse("2022-05-22"))
  end
  let!(:notification) do
    create(:notification, participation: participation_rdv, format: "email", sent_at: Time.zone.parse("2022-06-22"))
  end
  let!(:rdv_context) do
    create(
      :rdv_context, invitations: [first_invitation, last_invitation],
                    motif_category: motif_category, participations: [participation_rdv],
                    applicant: applicant1, status: "rdv_needs_status_update"
    )
  end
  let!(:referent) do
    create(:agent, email: "monreferent@gouv.fr")
  end

  let!(:applicants) { Applicant.where(id: [applicant1, applicant2, applicant3]) }

  describe "#call" do
    before { travel_to(now) }

    context "when the invitation deadline has passed" do
      let!(:rdv_context) do
        create(
          :rdv_context, invitations: [first_invitation, last_invitation],
                        participations: [], motif_category: motif_category,
                        applicant: applicant1, status: "invitation_pending"
        )
      end

      it "displays 'délai dépassé'" do
        expect(subject.csv).to include("Invitation en attente de réponse (Délai dépassé)") # rdv_context status
      end
    end

    context "it exports applicants to csv" do
      let!(:csv) { subject.csv }

      it "is a success" do
        expect(subject.success?).to eq(true)
      end

      it "generates a filename" do
        expect(subject.filename).to eq("Export_beneficiaires_rsa_orientation_organisation_drome_rsa.csv")
      end

      it "generates headers" do # rubocop:disable RSpec/ExampleLength
        expect(csv).to start_with("\uFEFF")
        expect(csv).to include("Civilité")
        expect(csv).to include("Nom")
        expect(csv).to include("Prénom")
        expect(csv).to include("Numéro d'allocataire")
        expect(csv).to include("ID interne au département")
        expect(csv).to include("Numéro de sécurité sociale")
        expect(csv).to include("ID Pôle Emploi")
        expect(csv).to include("ID interne au département")
        expect(csv).to include("Email")
        expect(csv).to include("Téléphone")
        expect(csv).to include("Date de naissance")
        expect(csv).to include("Date de création")
        expect(csv).to include("Date d'entrée flux")
        expect(csv).to include("Rôle")
        expect(csv).to include("Archivé le")
        expect(csv).to include("Motif d'archivage")
        expect(csv).to include("Statut")
        expect(csv).to include("Première invitation envoyée le")
        expect(csv).to include("Dernière invitation envoyée le")
        expect(csv).to include("Dernière convocation envoyée le")
        expect(csv).to include("Date du dernier RDV")
        expect(csv).to include("Heure du dernier RDV")
        expect(csv).to include("Motif du dernier RDV")
        expect(csv).to include("Nature du dernier RDV")
        expect(csv).to include("Dernier RDV pris en autonomie ?")
        expect(csv).to include("RDV honoré en - de 30 jours ?")
        expect(csv).to include("Date d'orientation")
        expect(csv).to include("Référent(s)")
        expect(csv).to include("Nombre d'organisations")
        expect(csv).to include("Nom des organisations")
      end

      context "it exports all the concerned applicants" do
        it "generates one line for each applicant required" do
          expect(csv.scan(/(?=\n)/).count).to eq(4) # one line per applicants + 1 line of headers
        end

        it "displays all the applicants" do
          expect(csv).to include("Doe")
          expect(csv).to include("Casubolo")
          expect(csv).to include("Blanc")
        end
      end

      context "it displays the right attributes" do
        let!(:applicants) { Applicant.where(id: [applicant1]) }

        it "displays the applicants attributes" do
          expect(csv.scan(/(?=\n)/).count).to eq(2) # we check there is only one applicant for this test
          expect(csv).to include("madame")
          expect(csv).to include("Doe")
          expect(csv).to include("Jane")
          expect(csv).to include("12345") # affiliation_number
          expect(csv).to include("33333") # department_internal_id
          expect(csv).to include(nir)
          expect(csv).to include("DDAAZZ") # pole_emploi_id
          expect(csv).to include("20 avenue de Ségur 75OO7 Paris")
          expect(csv).to include("jane@doe.com")
          expect(csv).to include("+33610101010")
          expect(csv).to include("20/12/1977") # birth_date
          expect(csv).to include("20/05/2022") # created_at
          expect(csv).to include("18/05/2022") # rights_opening_date
          expect(csv).to include("demandeur") # role
        end

        it "displays the invitations infos" do
          expect(csv).to include("21/05/2022") # first invitation date
          expect(csv).to include("22/05/2022") # last invitation date
          expect(csv).not_to include("(Délai dépassé)") # invitation delay
        end

        it "displays the notifications infos" do
          expect(csv).to include("22/06/2022") # last notification date
        end

        it "displays the rdvs infos" do
          expect(csv).to include("25/05/2022") # last rdv date
          expect(csv).to include("0h00") # last rdv time
          expect(csv).to include("RSA orientation sur site") # last rdv motif
          expect(csv).to include("individuel") # last rdv type
          expect(csv).to include("individuel;Oui") # last rdv taken in autonomy ?
          expect(csv).to include("Statut du RDV à préciser") # rdv_context status
          expect(csv).to include("Statut du RDV à préciser;Oui") # first rdv in less than 30 days ?
          expect(csv).to include("individuel;Oui;Statut du RDV à préciser;Oui;25/05/2022") # orientation date
        end

        it "displays the organisation infos" do
          expect(csv).to include("1")
          expect(csv).to include("Drome RSA")
        end

        it "displays the referent emails" do
          expect(csv).to include("monreferent@gouv.fr")
        end

        context "when the applicant is archived" do
          let!(:applicant1) do
            create(
              :applicant,
              organisations: [organisation],
              archives: [archive]
            )
          end
          let!(:archive) do
            create(
              :archive,
              created_at: Time.zone.parse("2022-06-20"),
              department: department, archiving_reason: "test"
            )
          end

          it "displays the archive infos" do
            expect(subject.csv).to include("20/06/2022") # archive status
            expect(subject.csv).to include("20/06/2022;test") # archive reason
          end

          it "does displays the archived status rather than the rdv_context status" do
            expect(subject.csv).not_to include("Statut du RDV à préciser")
            expect(subject.csv).to include("Archivé")
          end
        end
      end

      context "when no motif category is passed" do
        subject { described_class.call(applicants: applicants, structure: structure, motif_category: nil) }

        it "is a success" do
          expect(subject.success?).to eq(true)
        end

        it "generates the right filename" do
          expect(subject.filename).to eq("Export_beneficiaires_organisation_drome_rsa.csv")
        end

        it "does not display the statuses" do
          expect(subject.csv).not_to include("Statut du RDV à préciser")
        end
      end
    end
  end
end
