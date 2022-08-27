class Users::UnlocksPolicy < ApplicationPolicy
  # Unlocks should be done by resetting the password, don't allow access to any of these routes
  def new?
    return false
  end

  def create?
    return false
  end

  def show?
    return false
  end
end
