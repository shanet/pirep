class Users::PasswordsController < Devise::PasswordsController
  layout 'devise'

  def new
    authorize :new?, policy_class: Users::PasswordsPolicy
    super
  end

  def create
    authorize :create?, policy_class: Users::PasswordsPolicy
    super
  end

  def edit
    authorize :edit?, policy_class: Users::PasswordsPolicy
    super
  end

  def update
    authorize :update?, policy_class: Users::PasswordsPolicy
    super
  end
end
