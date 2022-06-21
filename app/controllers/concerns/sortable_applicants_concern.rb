module SortableApplicantsConcern
  def sort_applicants
    return @applicants = @applicants.order(created_at: :desc) if params[:sort].blank?

    @applicants = Applicant.where(id: @applicants.sort_by(&params[:sort].to_sym))
    @applicants = @applicants.reverse if params[:direction] == "desc"
  end
end
