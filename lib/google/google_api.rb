require 'haversine'
require 'exceptions'
require_relative 'google_api_stubs'

module GoogleApi
  def self.client
    unless Rails.application.credentials.google_api_key
      GoogleApiStubs.stub_requests(Service::API_HOST)
    end

    return Service.new
  end

  class Service
    API_HOST = 'https://maps.googleapis.com/maps/api/place'
    PLACE_RADIUS = 2000 # meters

    def place_photos(query, latitude, longitude)
      # First first "places" near the given coordinates for the given query
      response = Faraday.get("#{API_HOST}/findplacefromtext/json", {
        key: Rails.application.credentials.google_api_key,
        input: query,
        inputtype: :textquery,
        locationbias: "circle:#{PLACE_RADIUS}@#{latitude},#{longitude}",
        fields: [:place_id, :geometry].join(','),
      })

      raise Exceptions::GooglePhotosQueryFailed unless response.success?

      candidates = JSON.parse(response.body)['candidates']

      if candidates.empty?
        Rails.logger.info("No place candidates found for query #{query}, #{latitude}, #{longitude}")
        return []
      end

      # Reject anything not located around the given coordinates. The location bias specified above is just that: a bias. It won't prevent
      # Google from returning photos from a wildly different area if no better results exist. In our case, we know exactly the location
      # we're interested in so reject anything not in that area.
      result = candidates.find do |candidate|
        candidate_latitude = candidate.dig('geometry', 'location', 'lat')
        candidate_longitude = candidate.dig('geometry', 'location', 'lng')
        next false unless candidate_latitude && candidate_longitude

        next Haversine.new.distance(latitude, longitude, candidate_latitude, candidate_longitude) < PLACE_RADIUS # meters
      end

      # Don't return anything if no acceptable location was found as the probability of the photos being correct is extremely low
      unless result
        Rails.logger.info("All place candidates filtered for query #{query}, #{latitude}, #{longitude}")
        return []
      end

      response = Faraday.get("#{API_HOST}/details/json", {
        key: Rails.application.credentials.google_api_key,
        place_id: result['place_id'],
        fields: :photo,
      })

      raise Exceptions::GooglePhotosQueryFailed unless response.success?

      result = JSON.parse(response.body)['result']
      return [] unless result['photos']

      return result['photos'].reduce([]) do |photos, photo|
        response = Faraday.get("#{API_HOST}/photo", {
          key: Rails.application.credentials.google_api_key,
          photoreference: photo['photo_reference'],
          maxwidth: 1000, # px
        })

        raise Exceptions::GooglePhotosQueryFailed unless response.status == 302

        photos << {url: response.headers[:location], attribution: photo['html_attribution']&.first}
      end
    rescue => error
      # Don't be silent during tests
      raise error if Rails.env.test?

      Sentry.capture_exception(error)
      return []
    end
  end
end
