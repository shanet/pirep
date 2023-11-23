require 'exceptions'
require_relative 'aopa_api_stubs'

module AopaApi
  def self.client
    if Rails.env.development? || Rails.env.test?
      AopaApiStubs.stub_requests(Service::API_HOST)
    end

    return Service.new
  end

  class Service
    API_HOST = 'https://webapp.aopa.org/AirportsAPI/events'

    def fetch_events
      response = Faraday.post(API_HOST, {startDate: Time.zone.now.iso8601}.to_json, {'Content-Type' => 'application/json'})
      raise Exceptions::AopaEventsFetchFailed if response.status != 200 || response.body == ''

      return JSON.parse(response.body).map {|event| parse_event(event)}.compact
    end

  private

    def parse_event(raw_event)
      start_date = Time.zone.parse(raw_event['startDateTimeUTC']).in_time_zone(raw_event['timeZone'])
      end_date = Time.zone.parse(raw_event['endDateTimeUTC']).in_time_zone(raw_event['timeZone'])

      # The start/end dates need to be in local time in a regular time object as the event importer will set the time to the airport's timezone.
      # Thus we need to drop the timezone info entirely by creating a new time object (there must be a better way to do this... I hate timezones so much).
      return {
        name: raw_event['title'],
        start_date: Time.parse(start_date.localtime.strftime('%FT%T')), # rubocop:disable Rails/TimeZone
        end_date: Time.parse(end_date.localtime.strftime('%FT%T')), # rubocop:disable Rails/TimeZone
        latitude: raw_event['latitude'].to_f,
        longitude: raw_event['longitude'].to_f,
        url: raw_event['informationWebsite'],
        city: raw_event['city'],
        state: raw_event['stateProvince'],
      }
    rescue => error
      Rails.logger.info("Failed to parse AOPA event: #{raw_event}")
      Sentry.capture_exception(error)
      return nil
    end
  end
end
