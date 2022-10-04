class Manage::AirportPolicy < ApplicationPolicy
  def index?
    return admin?
  end

  def search?
    return admin?
  end

  def show?
    return admin?
  end

  def edit?
    return admin?
  end

  def update?
    return admin?
  end

  def update_version?
    return admin?
  end
end
