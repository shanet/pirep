class ActionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all
    end
  end
end
