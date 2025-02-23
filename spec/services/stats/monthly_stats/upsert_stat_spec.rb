describe Stats::MonthlyStats::UpsertStat, type: :service do
  subject { described_class.call(structure_type: structure_type, structure_id: structure_id, date_string: date_string) }

  let!(:department) { create(:department) }
  let!(:date_string) { "2022-03-17 12:00:00 +0100" }
  let!(:date) { date_string.to_date }
  let!(:stats_values) do
    {
      applicants_count_grouped_by_month: 1,
      rdvs_count_grouped_by_month: 2,
      sent_invitations_count_grouped_by_month: 3,
      rate_of_no_show_for_invitations_grouped_by_month: 4,
      rate_of_no_show_for_convocations_grouped_by_month: 9,
      average_time_between_invitation_and_rdv_in_days_by_month: 5,
      rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month: 7,
      rate_of_autonomous_applicants_grouped_by_month: 8
    }
  end
  let!(:stat) { create(:stat, statable_type: "Department", statable_id: department.id) }
  let!(:structure_type) { "Department" }
  let!(:structure_id) { department.id }

  describe "#call" do
    before do
      allow(Stats::MonthlyStats::ComputeForFocusedMonth).to receive(:call)
        .and_return(OpenStruct.new(success?: true, stats_values: stats_values))
      allow(Stat).to receive(:find_or_initialize_by)
        .and_return(stat)
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    context "when department" do
      it "finds or initializes stat record" do
        expect(Stat).to receive(:find_or_initialize_by)
          .with(statable_type: "Department", statable_id: department.id)
        subject
      end
    end

    context "when organisation" do
      let!(:organisation) { create(:organisation) }
      let!(:structure_type) { "Organisation" }
      let!(:structure_id) { organisation.id }

      it "finds or initializes stat record" do
        expect(Stat).to receive(:find_or_initialize_by)
          .with(statable_type: "Organisation", statable_id: organisation.id)
        subject
      end
    end

    it "calls the compute stats service" do
      expect(Stats::MonthlyStats::ComputeForFocusedMonth).to receive(:call)
        .with(stat: stat, date: date)
      subject
    end

    it "merges the monthly stats attributes retrieved to the existing stat record" do
      subject
      expect(stat.reload[:applicants_count_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 1 })
      expect(stat.reload[:rdvs_count_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 2 })
      expect(stat.reload[:sent_invitations_count_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 3 })
      expect(stat.reload[:rate_of_no_show_for_invitations_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 4 })
      expect(stat.reload[:rate_of_no_show_for_convocations_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 9 })
      expect(stat.reload[:average_time_between_invitation_and_rdv_in_days_by_month]).to eq(
        { date.strftime("%m/%Y") => 5 }
      )
      expect(stat.reload[:rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month]).to eq(
        { (date - 1.month).strftime("%m/%Y") => 7 }
      )
      expect(stat.reload[:rate_of_autonomous_applicants_grouped_by_month]).to eq({ date.strftime("%m/%Y") => 8 })
    end

    it "saves a stat record" do
      expect(stat).to receive(:save)
      subject
    end
  end
end
