class ActionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if @user.admin?
        return scope.all
      end

      # Users can only view their own actions
      return scope.where(user: @user)
    end
  end
end
