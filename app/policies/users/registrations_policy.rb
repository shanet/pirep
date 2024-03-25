class Users::RegistrationsPolicy < ApplicationPolicy
  def new?
    return !@user.disabled_at
  end

  def create?
    return !@user.disabled_at && Rails.configuration.read_only.disabled?
  end

  # Only allow users to view/edit themselves
  # Unknown users are not allowed
  def show?
    return unknown? == false && @user == @record
  end

  def activity?
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

  def update_timezone?
    return unknown? == false && @user == @record
  end

  def verify?
    return !@user.disabled_at
  end
end
