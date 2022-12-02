class Manage::DashboardPolicy < ApplicationPolicy
  def index?
    return admin?
  end

  def activity?
    return admin?
  end

  def update_read_only?
    return admin?
  end
end
