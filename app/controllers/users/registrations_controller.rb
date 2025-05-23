require 'cloudflare/cloudflare'

class Users::RegistrationsController < Devise::RegistrationsController
  layout :layout_for_action
  respond_to :html, :js

  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def new
    authorize :new?, policy_class: Users::RegistrationsPolicy
    super
  end

  def create
    authorize :create?, policy_class: Users::RegistrationsPolicy

    # Validate the anti-spam challenge (this is only intended to stop crawlers that simply try to create as many accounts as possible on any websites)
    unless Cloudflare.client.valid_turnstile_response?(params['cf-turnstile-response'])
      build_resource(sign_up_params)
      resource.validate
      resource.errors.add(:base, 'Anti-spam check failed')
      return render(request.xhr? ? :create : :new)
    end

    # New users should always be known users, not admins
    params[:user][:type] = 'Users::Known'

    super do |user|
      flash[:notice] = 'Account created successfully. Check your email ' if user.persisted?
    end
  end

  def show
    authorize current_user, policy_class: Users::RegistrationsPolicy
    @user = current_user
  end

  def activity
    authorize current_user, policy_class: Users::RegistrationsPolicy
    @actions = policy_scope(Action.where(user: current_user).order(created_at: :desc).page(params[:page]))
    @user = current_user
  end

  def edit
    authorize current_user, policy_class: Users::RegistrationsPolicy
    super
  end

  def update
    authorize current_user, policy_class: Users::RegistrationsPolicy
    super
  end

  def destroy
    authorize current_user, policy_class: Users::RegistrationsPolicy
    super
  end

  def update_timezone
    authorize current_user, policy_class: Users::RegistrationsPolicy

    if current_user.update(timezone: params[:timezone])
      head :ok
    else
      head :internal_server_error
    end
  end

  def verify
    authorize active_user, policy_class: Users::RegistrationsPolicy

    if Cloudflare.client.valid_turnstile_response?(params['cf-turnstile-response'])
      active_user.update!(verified_at: Time.zone.now) unless active_user.verified_at
      head :ok
    else
      head :forbidden
    end
  end

protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :type])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :timezone])
  end

  def after_sign_up_path_for(_user)
    return root_path
  end

  def after_update_path_for(_user)
    return user_path
  end

  def update_resource(resource, params)
    # If the user is requesting to change their password use the update method that enforces the current password was given
    if params[:password].present?
      resource.update_with_password(params)
    else
      params.delete(:current_password)
      resource.update_without_password(params)
    end
  end

  def layout_for_action
    return (action_name.in?(['new', 'create']) ? 'devise' : 'application')
  end
end
