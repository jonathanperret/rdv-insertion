describe Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays, type: :service do
  subject { described_class.call(rdv_contexts: rdv_contexts) }

  let(:date) { Time.zone.parse("17/03/2022 12:00") }

  let!(:rdv_contexts) { RdvContext.where(id: [rdv_context1, rdv_context2]) }

  # First rdv_context : 2 days delay between first invitation sent_at and first participation creation
  let!(:rdv_context1) { create(:rdv_context, created_at: date) }
  let!(:invitation1) { create(:invitation, created_at: date, sent_at: date, rdv_context: rdv_context1) }
  let!(:participation1) do
    create(:participation, rdv_context: rdv_context1, created_at: (date + 2.days), status: "seen")
  end
  let!(:rdv1) { create(:rdv, created_at: (date + 2.days), participations: [participation1]) }

  # Second rdv_context : 4 days delay between first invitation sent_at and first participation creation
  let!(:rdv_context2) { create(:rdv_context, created_at: date) }
  let!(:invitation2) { create(:invitation, created_at: date, sent_at: date, rdv_context: rdv_context2) }
  let!(:participation2) do
    create(:participation, rdv_context: rdv_context2, created_at: (date + 4.days), status: "seen")
  end
  let!(:rdv2) { create(:rdv, created_at: (date + 4.days), participations: [participation2]) }

  describe "#call" do
    let!(:result) { subject }

    it "is a success" do
      expect(result.success?).to eq(true)
    end

    it "renders a float" do
      expect(result.value).to be_a(Float)
    end

    it "computes the average time between first invitation and first rdv in days" do
      expect(result.value).to eq(3)
    end
  end
end
