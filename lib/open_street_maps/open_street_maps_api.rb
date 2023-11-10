require 'exceptions'
require_relative 'open_street_maps_api_stubs'

module OpenStreetMapsApi
  def self.client
    if Rails.env.development? || Rails.env.test?
      OpenStreetMapsApiStubs.stub_requests(Service::API_HOST)
    end

    return Service.new
  end

  class Service
    API_HOST = 'https://overpass-api.de/api/interpreter'
    EARTH_RADIUS = 6_378 # mi (https://en.wikipedia.org/wiki/Earth_radius)
    BOUNDING_BOX_OFFSET = 1.2 # kilometers

    def bounding_box(latitude, longitude)
      # Query for all airport-type elements around the given coordinates. This is not an exhaustive list but should cover the
      # types we're interested in while not asking for too much data in the case of larger airports with many elements.
      #
      # See for the complete list: https://wiki.openstreetmap.org/wiki/Key:aeroway?uselang=en
      response = send_query(build_query(latitude, longitude, ['runway', 'terminal', 'taxiway', 'apron', 'hangar']))
      return response if response[:elements].any?

      # If nothing was found try the more general "aerodrome" type
      # This isn't used above because this will typically be the entire airport property and some airports have large amounts
      # of undeveloped land that will result in a bounding box too large. Ideally we want only the developed parts.
      return send_query(build_query(latitude, longitude, ['aerodrome']))
    rescue Exceptions::OpenStreetMapsQueryFailed
      # For some large airports querying all of the above elements may fail. If so, try again
      # with just the runways and terminals which should get us a pretty good bounding box.
      return send_query(build_query(latitude, longitude, ['runway', 'terminal']))
    end

  private

    def send_query(query)
      # See for API server details: https://wiki.openstreetmap.org/wiki/Overpass_API#Public_Overpass_API_instances
      response = Faraday.post(API_HOST, data: query)
      raise Exceptions::OpenStreetMapsQueryFailed unless response.status == 200

      return JSON.parse(response.body).deep_symbolize_keys
    end

    def build_query(latitude, longitude, tags)
      # Define a bounding box for searching the nearby area for airport elements
      bounding_box = [
        offset(latitude, longitude, -BOUNDING_BOX_OFFSET),
        offset(latitude, longitude, BOUNDING_BOX_OFFSET),
      ].flatten

      # OSM has three basic elements: nodes, ways, and relations. In our case, we're interested in nodes and ways.
      # A way being a 2D line/area comprised of 1D nodes. The query below will search a bounding box for all nodes/ways
      # tagged as "aeroway" elements with the given tag values. Then it recursively gets all nodes that any matched
      # ways are comprised of. From here, the caller of this method can parse the ways/nodes to construct the bounding
      # box of the airport.
      #
      # Intro guide to Overpass QL: https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide
      return <<~OPQL
        [out:json];
        (way(#{bounding_box.join(',')})["aeroway"~"#{tags.join('|')}"];);
        (._;>;);
        out qt;
      OPQL
    end

    def offset(latitude, longitude, kilometers)
      latitude_offset = (kilometers / EARTH_RADIUS) * (180 / Math::PI)
      longitude_offset = (kilometers / EARTH_RADIUS) * (180 / Math::PI) / Math.cos(latitude * Math::PI / 180)

      return [latitude + latitude_offset, longitude + longitude_offset]
    end
  end
end
