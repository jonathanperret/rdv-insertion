Stat.find_each do |stat|
  stat.rate_of_autonomous_applicants =
    Stats::ComputeRateOfAutonomousApplicants.call(applicants: stat.invited_applicants_sample).value

  date = stat.statable&.created_at || Time.zone.parse("01/01/2022 12:00")
  stat.rate_of_autonomous_applicants_grouped_by_month = {}

  while date < Time.zone.parse("31/08/2023 12:00")
    autonomous_rate = stat.rate_of_autonomous_applicants_grouped_by_month
    autonomous_rate_for_date =
      Stats::ComputeRateOfAutonomousApplicants.call(
        applicants: stat.invited_applicants_sample.where(created_at: date.all_month)
      ).value.round

    # We don't want to start the hash until we have a value
    if autonomous_rate != {} || autonomous_rate_for_date != 0
      autonomous_rate.merge!({ date.strftime("%m/%Y") => autonomous_rate_for_date })
      stat.rate_of_autonomous_applicants_grouped_by_month = autonomous_rate
    end

    date += 1.month
  end

  stat.save!
end
