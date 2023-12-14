class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_sentry_context
  before_action :set_paper_trail_whodunnit
  before_action :touch_user_seen
  after_action :verify_authorized

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::BadRequest, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

private

  def not_found(_exception=nil, message: nil)
    render_error(request&.format&.symbol, :not_found, message)
  end

  def forbidden(_exception=nil, message: nil)
    render_error(request&.format&.symbol, :forbidden, message)
  end

  def bad_request(_exception=nil, message: nil)
    render_error(request&.format&.symbol, :bad_request, message)
  end

  def internal_server_error(_exception=nil, message: nil)
    render_error(request&.format&.symbol, :internal_server_error, message)
  end

  def render_error(format, status, message)
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]

    case format
      when :json, :ical
        render json: {error: status.to_s, **(message ? {message: message} : {})}, status: status
      else
        # These are static pages so skip the CSP
        headers.merge!('Content-Security-Policy' => '')

        render file: Rails.public_path.join("#{status_code}.html"), formats: [:html], status: status, layout: false
    end
  end

  def active_user(create_unknown: true)
    return current_user if current_user

    # Create a new unknown user if requested. We may want to skip this so we're not creating users on each page view for example.
    method = (create_unknown ? :create_or_find_by! : :find_by)
    return Users::Unknown.send(method, ip_address: request.ip)
  end

  # Tell Pundit to use the active user wrapper instead of current user directly
  def pundit_user
    return active_user
  end

  def user_for_paper_trail
    return active_user.id
  end

  def touch_user_seen
    return unless active_user(create_unknown: false)

    # Keep track of when a user was last seen on the site
    active_user.touch :last_seen_at # rubocop:disable Rails/SkipsModelValidations
  end

  def touch_user_edit
    return unless active_user(create_unknown: false)

    # Keep track of when a user last made an edit
    active_user&.touch(:last_edit_at) # rubocop:disable Rails/SkipsModelValidations
  end

  def set_sentry_context
    return unless current_user

    Sentry.set_user(id: current_user.id)
  end

  def spider?
    # This isn't perfect, but well behaved spiders will usually have a URL in their user agent.
    # If it doesn't it's probably not a well behaved spider anyway so there's not much use in playing games with it.
    return !(request.env['HTTP_USER_AGENT'] =~ /.*https?:\/\/.*/).nil?
  end
end
