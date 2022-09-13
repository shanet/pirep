class TagPolicy < ApplicationPolicy
  def destroy?
    return true
  end

  def revert?
    return admin?
  end
end
