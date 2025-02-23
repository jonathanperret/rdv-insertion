describe "Agents can upload applicant list", js: true do
  include_context "with file configuration"

  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department,
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
      # needed for the organisation applicants page
      configurations: [configuration],
      slug: "org1"
    )
  end
  let!(:motif) { create(:motif, organisation: organisation, motif_category: motif_category) }

  let!(:configuration) do
    create(:configuration, motif_category: motif_category, file_configuration: file_configuration)
  end

  let!(:other_org_from_same_department) { create(:organisation, department: department) }
  let!(:other_department) { create(:department) }
  let!(:other_org_from_other_department) { create(:organisation, department: other_department) }

  let!(:now) { Time.zone.parse("05/10/2022") }

  let!(:motif_category) { create(:motif_category) }
  let!(:rdv_solidarites_user_id) { 2323 }
  let!(:rdv_solidarites_organisation_id) { 3234 }

  before do
    setup_agent_session(agent)
    stub_applicant_creation(rdv_solidarites_user_id)
    organisation.tags << create(:tag, value: "Gentils")
  end

  context "at organisation level" do
    before { travel_to now }

    it "can edit an applicant infos" do
      visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

      attach_file("applicants-list-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

      click_button("Créer compte")

      editable_columns = [2, 3, 4, 6, 11]

      editable_columns.each do |index|
        column = find("tr:first-child td:nth-child(#{index})")
        column.double_click

        case index
        when 2
          column.find("select").set("Madame")
          expect(column).to have_content("Mme")
        when 6
          column.find("select option[value=conjoint]").select_option
          expect(column).to have_content("CJT")
        when 11
          column
            .double_click

          modal = find(".modal")

          modal.find("select option[value=Gentils]").select_option
          modal.click_button("Ajouter")
          modal.click_button("Fermer")

          expect(column).to have_content("Gentils")
        else
          column
            .double_click
            .find("input")
            .set("hello")
            .send_keys(:enter)

          expect(column).to have_content("hello")
        end
      end

      expect(Applicant.last.first_name).to eq("hello")
      expect(Applicant.last.last_name).to eq("hello")
    end
  end
end
