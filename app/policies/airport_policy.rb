class AirportPolicy < ApplicationPolicy
  def index?
    return true
  end

  def new?
    return !@user.disabled_at
  end

  def create?
    return !@user.disabled_at && Rails.configuration.read_only.disabled?
  end

  def show?
    return true
  end

  def update?
    return !@user.disabled_at && !@record.locked_at && Rails.configuration.read_only.disabled?
  end

  def search?
    return true
  end

  def basic_search?
    return true
  end

  def advanced_search?
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

  def annotations?
    return true
  end

  def uncached_photo_gallery?
    return true
  end
end
