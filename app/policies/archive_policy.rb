class ArchivePolicy < ApplicationPolicy
  def create?
    # agent must belong to all orgs where the applicant is present inside the department
    record.applicant.organisations.all? do |organisation|
      organisation.department_id != record.department_id ||
        organisation.id.in?(pundit_user.organisation_ids)
    end
  end

  def destroy?
    pundit_user.organisation_ids.intersect?(record.applicant.organisation_ids)
  end
end
