class AirportPolicy < ApplicationPolicy
  def index?
    return true
  end

  def show?
    return true
  end

  def update?
    return !@user.disabled_at
  end

  def search?
    return true
  end

  def history?
    return true
  end

  def preview?
    return true
  end

  def revert?
    return admin?
  end
end
