require 'action_view'
require 'haversine'
require 'exceptions'
require_relative 'google_api_stubs'

module GoogleApi
  include ActionView::Helpers::SanitizeHelper

  def self.client
    if Rails.application.credentials.google_api_key
      # Allow real connections in development when credentials are set since other services may stub their endpoints
      WebMock.allow_net_connect!(allow: /https:\/\/maps\.googleapis\.com/) if Rails.env.development?
    else
      GoogleApiStubs.stub_requests(Service::API_PLACE_PHOTOS, Service::API_TIMEZONES)
    end

    return Service.new
  end

  class Service
    include ActionView::Helpers::SanitizeHelper

    API_PLACE_PHOTOS = 'https://maps.googleapis.com/maps/api/place'
    API_TIMEZONES = 'https://maps.googleapis.com/maps/api/timezone/json'
    PLACE_RADIUS = 2000 # meters

    def place_photos(query, latitude, longitude, place_id: nil)
      place_id = place_id_lookup(query, latitude, longitude) unless place_id

      # There's no photos to return if we still don't have a place ID
      return {place_id: nil, photos: []} unless place_id

      response = Faraday.get("#{API_PLACE_PHOTOS}/details/json", {
        key: Rails.application.credentials.google_api_key,
        place_id: place_id,
        fields: :photo,
      })

      raise Exceptions::GooglePhotosQueryFailed unless response.success?

      result = JSON.parse(response.body)['result']
      return {place_id: place_id, photos: []} unless result['photos']

      photos = result['photos'].reduce([]) do |photos, photo|
        response = Faraday.get("#{API_PLACE_PHOTOS}/photo", {
          key: Rails.application.credentials.google_api_key,
          photoreference: photo['photo_reference'],
          maxwidth: 1000, # px
        })

        raise Exceptions::GooglePhotosQueryFailed unless response.status == 302

        attribution = photo['html_attributions']&.join(', ')
        attribution = sanitize(attribution, tags: ['a'], attributes: ['href']) if attribution.present?

        photos << {url: response.headers[:location], attribution: attribution, google_photo_reference: photo['photo_reference']}
      end

      return {place_id: place_id, photos: photos}
    rescue => error
      # Don't be silent during dev/tests
      raise error if Rails.env.local?

      Sentry.capture_exception(error)
      return {place_id: nil, photos: []}
    end

    def place_id_lookup(query, latitude, longitude)
      # First find "places" near the given coordinates for the given query
      response = Faraday.get("#{API_PLACE_PHOTOS}/findplacefromtext/json", {
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
        return nil
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
        return nil
      end

      return result['place_id']
    end

    def timezone(latitude, longitude)
      response = Faraday.get(API_TIMEZONES, {
        key: Rails.application.credentials.google_api_key,
        location: "#{latitude},#{longitude}",
        timestamp: Time.zone.now.to_i,
      })

      raise Exceptions::GoogleTimezoneQueryFailed unless response.success?

      return JSON.parse(response.body)['timeZoneId']
    rescue => error
      # Don't be silent during tests
      raise error if Rails.env.test?

      Sentry.capture_exception(error)
      return nil
    end
  end
end
