class VersionPolicy < ApplicationPolicy
  def revert?
    return admin?
  end
end
