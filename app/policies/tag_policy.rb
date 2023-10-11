class TagPolicy < ApplicationPolicy
  def destroy?
    return !@user.disabled_at && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def revert?
    return admin?
  end
end
