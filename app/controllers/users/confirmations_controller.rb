class Users::ConfirmationsController < Devise::ConfirmationsController
  layout 'devise'

  def new
    authorize :new?, policy_class: Users::ConfirmationsPolicy
    super
  end

  def create
    authorize :create?, policy_class: Users::ConfirmationsPolicy
    super
  end

  def show
    authorize :show?, policy_class: Users::ConfirmationsPolicy
    super
  end
end
