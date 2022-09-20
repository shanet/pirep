class Users::RegistrationsPolicy < ApplicationPolicy
  def new?
    return true
  end

  def create?
    return true
  end

  # Only allow users to view/edit themselves
  # Unknown users are not allowed
  def show?
    return unknown? == false && @user == @record
  end

  def edit?
    return unknown? == false && @user == @record
  end

  def update?
    return unknown? == false && @user == @record
  end

  def destroy?
    return unknown? == false && @user == @record
  end
end
