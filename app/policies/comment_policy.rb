class CommentPolicy < ApplicationPolicy
  def create?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def helpful?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def flag_outdated?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def undo_outdated?
    return !@user.disabled_at && @user.verified? && !@record.airport.locked_at && Rails.configuration.read_only.disabled?
  end

  def destroy?
    return admin?
  end
end
