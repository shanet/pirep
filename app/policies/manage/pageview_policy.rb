class Manage::PageviewPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return (@user.admin? ? scope.all : scope.none)
    end
  end
end
