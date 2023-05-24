class Manage::VersionPolicy < ApplicationPolicy
  def update?
    return admin?
  end
end
