class Users::PasswordsPolicy < ApplicationPolicy
  def new?
    return true
  end

  def create?
    return true
  end

  def edit?
    return true
  end

  def update?
    return true
  end
end
