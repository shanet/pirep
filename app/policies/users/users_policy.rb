class Users::UsersPolicy < ApplicationPolicy
  def show?
    return true
  end

  def activity?
    return true
  end
end
