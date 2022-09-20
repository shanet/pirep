class Manage::DashboardPolicy < ApplicationPolicy
  def index?
    return admin?
  end

  def activity?
    return admin?
  end
end
