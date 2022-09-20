module ApplicationHelper
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

  def format_timestamp(timestamp)
    return timestamp&.strftime('%F %T')
  end

  def gravatar_url(email_address, size: nil)
    hash = Digest::MD5.hexdigest(email_address.downcase)
    return "https://www.gravatar.com/avatar/#{hash}#{size ? "?s=#{size}" : ''}"
  end

  def render_markdown(text)
    return '' if text.blank?

    return sanitize(Kramdown::Document.new(text).to_html)
  end

  def user_label(user)
    return (user.unknown? ? user.ip_address : user.email)
  end
end
