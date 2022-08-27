class Users::ConfirmationsPolicy < ApplicationPolicy
  def new?
    return true
  end

  def create?
    return true
  end

  def show?
    return true
  end
end
