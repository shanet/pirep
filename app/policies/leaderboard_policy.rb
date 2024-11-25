class LeaderboardPolicy < ApplicationPolicy
  def index?
    return true
  end

  class Scope < Scope
    def resolve
      return scope.all
    end
  end
end
