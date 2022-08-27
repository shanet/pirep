class Users::SessionsController < Devise::SessionsController
  layout 'devise'
  respond_to :html, :js

  def new
    authorize :new?, policy_class: Users::SessionsPolicy
    super
  end

  def create
    authorize :create?, policy_class: Users::SessionsPolicy

    super do
      # If the user was signed in and it's an XHR request respond with the appropriate redirect. Otherwise, let the default devise behavior handle it
      next unless current_user && request.xhr?

      @redirect = after_sign_in_path_for(current_user)
      return render :create
    end
  end

  def destroy
    authorize :destroy?, policy_class: Users::SessionsPolicy
    super
  end

protected

  def after_sign_in_path_for(user)
    # Go the page the user was attempting to access before login if one is set
    return session['user_return_to'] if session['user_return_to'].present?

    return manage_root_path if user.is_a? Users::Admin

    return root_path
  end
end
