class Manage::AttachmentPolicy < ApplicationPolicy
  def index?
    return admin?
  end

  def destroy?
    return admin?
  end

  class Scope < Scope
    def resolve
      return (@user.admin? ? scope.all : scope.none)
    end
  end
end
