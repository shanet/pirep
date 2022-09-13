class ApplicationController < ActionController::Base
  include Pundit::Authorization

  after_action :verify_authorized
  before_action :set_paper_trail_whodunnit

  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from ActionController::BadRequest, with: :render_bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

private

  def not_found(format=nil, message: nil)
    render_error(format, :not_found, message)
  end

  def forbidden(format=nil, message: nil)
    render_error(format, :forbidden, message)
  end

  def bad_request(format=nil, message: nil)
    render_error(format, :internal_server_error, message)
  end

  def render_error(format, status, message)
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]

    case format
      when :json
        render json: {error: status.to_s, message: message}, status: status
      else
        render file: Rails.public_path.join('errors', "#{status_code}.html"), formats: [:html], status: status, layout: false
    end
  end
end
