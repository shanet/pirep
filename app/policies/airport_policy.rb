class AirportPolicy < ApplicationPolicy
  def index?
    return true
  end

  def show?
    return true
  end

  def update?
    return true
  end

  def search?
    return true
  end
end
