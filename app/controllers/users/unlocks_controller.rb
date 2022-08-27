class Users::UnlocksController < Devise::UnlocksController
  def new
    authorize :new?, policy_class: Users::UnlocksPolicy
    super
  end

  def create
    authorize :create?, policy_class: Users::UnlocksPolicy
    super
  end

  def show
    authorize :show?, policy_class: Users::UnlocksPolicy
    super
  end
end
