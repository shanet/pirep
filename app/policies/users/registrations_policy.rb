class Users::RegistrationsPolicy < ApplicationPolicy
  def new?
    return true
  end

  def create?
    return true
  end

  # Only allow users to view/edit themselves
  def show?
    return @user == @record
  end

  def edit?
    return @user == @record
  end

  def update?
    return @user == @record
  end

  def destroy?
    return @user == @record
  end
end
