require 'maxmind/maxmind_db'

class MapController < ApplicationController
  layout 'map'

  def index
    authorize :map

    # Center the map on the user's geoip location or default to the center of the continental US if this fails
    geoip = (request.remote_ip ? MaxmindDb.client.geoip_lookup(request.remote_ip) : nil)

    @center = geoip || {latitude: 39.82834557323, longitude: -98.57944574225633}
    @zoom_level = (geoip ? 7.5 : 4)
  end
end
