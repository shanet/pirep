class EventPolicy < ApplicationPolicy
  def create?
    return !@user.disabled_at && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def edit?
    return !@user.disabled_at && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def update?
    return !@user.disabled_at && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def show?
    return true
  end

  def destroy?
    return !@user.disabled_at && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def revert?
    return admin?
  end
end
