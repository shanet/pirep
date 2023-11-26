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

      return {
        name: raw_event['title'],
        start_date: start_date.strftime('%FT%T'),
        end_date: end_date.strftime('%FT%T'),
        latitude: raw_event['latitude'].to_f,
        longitude: raw_event['longitude'].to_f,
        url: raw_event['informationWebsite'],
        city: raw_event['city'],
        state: raw_event['stateProvince'],
      }
    rescue => error
      Rails.logger.info("Failed to parse AOPA event: #{raw_event}")
      Sentry.capture_exception(error)
      raise error if Rails.env.test?

      return nil
    end
  end
end
