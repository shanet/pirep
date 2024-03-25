class WebcamPolicy < ApplicationPolicy
  def create?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def destroy?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def revert?
    return admin?
  end
end
