require 'maxmind/maxmind_db'

module Manage::UsersHelper
  def google_maps_location_link(ip_address, label=nil)
    geoip = geoip_lookup(ip_address)
    return 'Unknown' unless geoip

    label ||= "#{geoip[:latitude]}, #{geoip[:longitude]}"
    url = "https://google.com/maps?q=#{geoip[:latitude]}%2C#{geoip[:longitude]}&ll=#{geoip[:latitude]}%2C#{geoip[:longitude]}&z=7"

    return link_to(label, url, target: :_blank, rel: 'noopener')
  end

  def geoip_lookup(ip_address)
    return MaxmindDb.client.geoip_lookup(ip_address)
  end
end
