module Manage::UsersHelper
  def google_maps_location_link(ip_address)
    geoip = MaxmindDb.client.geoip_lookup(ip_address)
    return 'Unknown' unless geoip

    url = "https://google.com/maps?q=#{geoip[:latitude]}%2C#{geoip[:longitude]}&ll=#{geoip[:latitude]}%2C#{geoip[:longitude]}&z=7"
    return link_to("#{geoip[:latitude]}, #{geoip[:longitude]}", url, target: :_blank, rel: 'noopener')
  end
end
