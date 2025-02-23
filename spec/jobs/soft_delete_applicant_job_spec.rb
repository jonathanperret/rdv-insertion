describe SoftDeleteApplicantJob do
  subject do
    described_class.new.perform(rdv_solidarites_user_id)
  end

  let!(:rdv_solidarites_user_id) { { id: 1 } }
  let!(:applicant) { create(:applicant) }

  describe "#perform" do
    before do
      allow(Applicant).to receive(:find_by)
        .with(rdv_solidarites_user_id: rdv_solidarites_user_id)
        .and_return(applicant)
      allow(MattermostClient).to receive(:send_to_notif_channel)
    end

    it "finds the matching applicant" do
      expect(Applicant).to receive(:find_by)
        .with(rdv_solidarites_user_id: rdv_solidarites_user_id)
      subject
    end

    it "soft deletes the applicant" do
      subject
      expect(applicant.deleted_at).not_to be_nil
      expect(applicant.uid).to eq(nil)
      expect(applicant.department_internal_id).to eq(nil)
      expect(applicant.affiliation_number).to eq(nil)
      expect(applicant.role).to eq(nil)
    end
  end
end
