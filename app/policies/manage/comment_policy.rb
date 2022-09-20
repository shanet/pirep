class Manage::CommentPolicy < ApplicationPolicy
  def index?
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
end
