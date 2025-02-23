class DepartmentPolicy < ApplicationPolicy
  def upload?
    pundit_user.organisation_ids.intersect?(record.organisation_ids)
  end

  def index?
    upload?
  end

  class Scope < Scope
    def resolve
      Department.where(id: pundit_user.organisations.pluck(:department_id))
    end
  end
end
