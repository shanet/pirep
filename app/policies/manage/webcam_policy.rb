class Manage::WebcamPolicy < ApplicationPolicy
  def destroy?
    return admin?
  end
end
