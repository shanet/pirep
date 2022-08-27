class Manage::DashboardPolicy < ApplicationPolicy
  def index?
    return admin?
  end
end
