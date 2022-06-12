module FilterableApplicantsConcern
  def filter_and_sort_applicants
    filter_applicants_by_search_query
    filter_applicants_by_action_required
    filter_applicants_by_status
    sort_applicants
    filter_applicants_by_page
  end

  def filter_applicants_by_status
    return if params[:status].blank?

    @applicants = @applicants.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.status(params[:status]))
  end

  def filter_applicants_by_action_required
    return unless params[:action_required] == "true"

    @applicants = @applicants.joins(:rdv_contexts).where(
      rdv_contexts: @rdv_contexts.action_required(@current_configuration.number_of_days_before_action_required)
    )
  end

  def filter_applicants_by_search_query
    return if params[:search_query].blank?

    # with_pg_search_rank scope added to be compatible with distinct https://github.com/Casecommons/pg_search/issues/238
    @applicants = @applicants.search_by_text(params[:search_query]).with_pg_search_rank
  end

  def sort_applicants
    return @applicants = @applicants.order(created_at: :desc) if params[:sort].blank?

    sort_applicants_by_first_invitation_date if params[:sort] == "first_invitation_sent_at"
    sort_applicants_by_last_invitation_date if params[:sort] == "last_invitation_sent_at"
  end

  def sort_applicants_by_first_invitation_date
    @applicants = @applicants.sort_by(&:first_invitation_sent_at)
  end

  def sort_applicants_by_last_invitation_date
    @applicants = @applicants.joins(:invitations).order("invitations.select(&:sent_at).min_by(&:sent_at)&.sent_at").group("applicants.id")
  end

  def filter_applicants_by_page
    return if request.format == "csv"

    # @applicants = @applicants.page(page)
  end
end
