class Users::SessionsPolicy < ApplicationPolicy
  def new?
    return true
  end

  def create?
    return true
  end

  def destroy?
    # Only allow a sign out if already signed in
    return unknown? == false
  end
end
