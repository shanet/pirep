class Manage::UserPolicy < ApplicationPolicy
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

  def destroy?
    return admin?
  end

  def activity?
    return admin?
  end
end
