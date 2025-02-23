describe CreateAndInviteApplicantJob do
  subject do
    described_class.new.perform(
      organisation_id, applicant_attributes, invitation_params, rdv_solidarites_session_credentials
    )
  end

  let!(:organisation_id) { 99 }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department, id: organisation_id, phone_number: "0146292929"
    )
  end
  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation") }
  let!(:configuration) { create(:configuration, organisation: organisation, motif_category: motif_category) }
  let!(:applicant) { create(:applicant) }
  let!(:applicant_attributes) do
    { department_internal_id: "1919", affiliation_number: "00001", role: "conjoint", phone_number: "0607070707",
      email: "john.doe@apijob.com" }
  end
  let!(:invitation_params) { { rdv_solidarites_lieu_id: 888 } }
  let!(:sms_invitation_attributes) do
    { help_phone_number: "0146292929", format: "sms", rdv_solidarites_lieu_id: 888 }
  end
  let!(:email_invitation_attributes) do
    { help_phone_number: "0146292929", format: "email", rdv_solidarites_lieu_id: 888 }
  end
  let!(:rdv_solidarites_session_credentials) do
    { "client" => "someclient", "uid" => "janedoe@gouv.fr", "access_token" => "sometoken" }.symbolize_keys
  end

  before do
    allow(Applicants::FindOrInitialize).to receive(:call)
      .with(attributes: applicant_attributes, department_id: department.id)
      .and_return(OpenStruct.new(success?: true, applicant: applicant))
    allow(Applicants::Save).to receive(:call).and_return(OpenStruct.new(success?: true, failure?: false))
    allow(InviteApplicantJob).to receive(:perform_async)
    allow(RdvSolidaritesSessionFactory).to receive(:create_with)
      .with(**rdv_solidarites_session_credentials)
      .and_return(rdv_solidarites_session)
  end

  it "assigns the attributes" do
    expect(applicant).to receive(:assign_attributes).with(applicant_attributes)
    subject
  end

  it "saves the applicant" do
    expect(Applicants::Save).to receive(:call)
      .with(applicant: applicant, organisation: organisation, rdv_solidarites_session: rdv_solidarites_session)
    subject
  end

  it "enqueues invite applicant jobs" do
    expect(InviteApplicantJob).to receive(:perform_async)
      .with(
        applicant.id, organisation.id, sms_invitation_attributes, motif_category.id,
        rdv_solidarites_session_credentials
      )
    expect(InviteApplicantJob).to receive(:perform_async)
      .with(
        applicant.id, organisation.id, email_invitation_attributes, motif_category.id,
        rdv_solidarites_session_credentials
      )
    subject
  end

  context "when there is no phone" do
    before { applicant_attributes[:phone_number] = nil }

    it "does not enqueue an invite sms job" do
      expect(InviteApplicantJob).not_to receive(:perform_async)
        .with(
          applicant.id, organisation.id, sms_invitation_attributes, motif_category.id,
          rdv_solidarites_session_credentials
        )
      subject
    end
  end

  context "when the phone is not a mobile" do
    before { applicant_attributes[:phone_number] = "0101010101" }

    it "does not enqueue an invite sms job" do
      expect(InviteApplicantJob).not_to receive(:perform_async)
        .with(
          applicant.id, organisation.id, sms_invitation_attributes, motif_category, rdv_solidarites_session_credentials
        )
      subject
    end
  end

  context "when there is no email" do
    before { applicant_attributes[:email] = nil }

    it "does not enqueue an invite email job" do
      expect(InviteApplicantJob).not_to receive(:perform_async)
        .with(
          applicant.id, organisation.id,
          email_invitation_attributes, motif_category.id, rdv_solidarites_session_credentials
        )
      subject
    end
  end

  context "when a motif category is specified" do
    let!(:category_accompagnement) { create(:motif_category, name: "RSA accompagnement") }
    let!(:new_configuration) do
      create(:configuration, organisation: organisation, motif_category: category_accompagnement)
    end
    let!(:invitation_params) { { rdv_solidarites_lieu_id: 888, motif_category_name: "RSA accompagnement" } }

    it "enqueues invite applicant jobs with the specified context" do
      expect(InviteApplicantJob).to receive(:perform_async)
        .with(
          applicant.id,
          organisation.id, sms_invitation_attributes, category_accompagnement.id, rdv_solidarites_session_credentials
        )
      expect(InviteApplicantJob).to receive(:perform_async)
        .with(
          applicant.id,
          organisation.id, email_invitation_attributes, category_accompagnement.id, rdv_solidarites_session_credentials
        )
      subject
    end
  end

  context "when the instantation fails" do
    let!(:department_mail) { instance_double("mail") }

    before do
      allow(Applicants::FindOrInitialize).to receive(:call)
        .and_return(OpenStruct.new(success?: false, errors: ["NIR does not match"]))
      allow(DepartmentMailer).to receive(:create_applicant_error).and_return(department_mail)
      allow(department_mail).to receive(:deliver_now)
    end

    it "sends an email to the department and raises" do
      expect(DepartmentMailer).to receive(:create_applicant_error)
        .with(department, applicant_attributes, ["NIR does not match"])
      expect(department_mail).to receive(:deliver_now)
      expect { subject }.to raise_error(
        FailedServiceError,
        'Error initializing applicant in CreateAndInviteApplicantJob: ["NIR does not match"]'
      )
    end
  end

  context "when the save fails" do
    let!(:department_mail) { instance_double("mail") }

    before do
      allow(Applicants::Save).to receive(:call)
        .and_return(OpenStruct.new(success?: false, errors: ["could not save applicant"]))
      allow(Sentry).to receive(:capture_exception)
      allow(DepartmentMailer).to receive(:create_applicant_error).and_return(department_mail)
      allow(department_mail).to receive(:deliver_now)
    end

    it "sends an email to the department and raises" do
      expect(DepartmentMailer).to receive(:create_applicant_error)
        .with(department, applicant_attributes, ["could not save applicant"])
      expect(department_mail).to receive(:deliver_now)
      expect { subject }.to raise_error(
        FailedServiceError,
        'Error saving applicant in CreateAndInviteApplicantJob: ["could not save applicant"]'
      )
    end
  end
end
