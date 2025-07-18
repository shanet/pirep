module ApplicationHelper
  def active_user
    return current_user || Users::Unknown.find_by(ip_address: request.ip)
  end

  def flash_to_class(flash_type)
    flash_type = flash_type.to_sym

    # Treat `alert` and `error` as the same types
    flash_type = :error if flash_type == :alert

    # Convert Rails flash types to Bootstrap classes
    return {
      error: {class: 'danger', icon: 'fa-triangle-exclamation'},
      notice: {class: 'primary', icon: 'fa-circle-check'},
      warning: {class: 'warning', icon: 'fa-triangle-exclamation'},
    }[flash_type]
  end

  def format_timestamp(timestamp, format: nil, timezone: nil)
    timestamp = timestamp&.in_time_zone(timezone || current_user&.timezone.presence || Rails.configuration.time_zone)
    return timestamp&.strftime(format || '%F %T %Z')
  end

  def gravatar_url(email_address, size: nil)
    hash = Digest::MD5.hexdigest(email_address.downcase)
    return "https://www.gravatar.com/avatar/#{hash}#{"?s=#{size}" if size}"
  end

  def faa_data_content_url(product, filename: nil, path: nil)
    host = (product == :charts ? Rails.configuration.try(:tiles_host) : Rails.configuration.action_controller.asset_host) # rubocop:disable Rails/SafeNavigation

    return File.join(
      host.presence || '',
      Rails.configuration.try(:cdn_content_path).presence || 'assets', # rubocop:disable Rails/SafeNavigation
      (path || product).to_s,
      Rails.configuration.faa_data_cycle.current(product),
      filename || ''
    ).to_s
  end

  # Use the CDN for attached files if we have one set
  def cdn_url_for(record)
    return "#{Rails.configuration.action_controller.asset_host}/#{record.key}" if Rails.configuration.action_controller.asset_host.present?

    # This seems to be necessary in Rails 8 now due to lazy loaded routes in dev/test?
    Rails.application.reload_routes_unless_loaded if Rails.env.local?

    return url_for(record)
  end

  def render_markdown(text)
    return '' if text.blank?

    return sanitize(Kramdown::Document.new(text).to_html.strip)
  end

  def user_label(user)
    return (user.unknown? ? user.ip_address : user.email)
  end

  def public_user_label(user)
    return (user.unknown? ? user.ip_address : user.name.presence || t(:anonymous_label))
  end

  def active_path?(route, exact: false) # rubocop:disable Naming/PredicateMethod
    if exact
      return (request.path == route ? 'active' : '')
    end

    return (request.path.start_with?(route) ? 'active' : '')
  end

  # Wrap the current page method to gracefully handle actions that don't exist for the current resource
  def current_page?(...)
    return super
  rescue ActionController::UrlGenerationError
    return false
  end
end
