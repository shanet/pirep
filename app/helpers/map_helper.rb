module MapHelper
  def filter_icon(icon)
    return "<i class=\"fas fa-#{icon}\"></i>".html_safe
  end

  def cached_airports_path
    if Rails.configuration.action_controller.asset_host
      return airports_url(host: Rails.configuration.action_controller.asset_host, digest: AirportGeojsonCacher.read_digest)
    end

    return airports_path
  end
end
