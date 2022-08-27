class TagPolicy < ApplicationPolicy
  def destroy?
    return true
  end
end
