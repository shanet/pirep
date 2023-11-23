require 'exceptions'
require_relative 'eaa_api_stubs'

module EaaApi
  def self.client
    if Rails.env.development? || Rails.env.test?
      EaaApiStubs.stub_requests(Service::API_HOST)
    end

    return Service.new
  end

  class Service
    API_HOST = 'https://www.eaa.org/SpecialUseComponents/Event/GetEvents'
    EVENT_DATE_REGEX = /\/Date\((\d+)\)\//

    def fetch_events
      query = {
        contextId: 'd8056eaa-5550-486f-a67c-d8bbcddf23ad',
        pageSize: '1000',
        startDate: Time.zone.now.strftime('%m/%d/%Y'),
        endDate: 1.year.from_now.strftime('%m/%d/%Y'),
      }

      response = Faraday.post(API_HOST, query.to_json, {'Content-Type' => 'application/json'})
      raise Exceptions::EaaEventsFetchFailed if response.status != 200 || response.body == ''

      return JSON.parse(response.body)['CalendarItems'].map {|event| parse_event(event)}.compact
    end

  private

    def parse_event(raw_event)
      # The event times will need to be put into the local timezone of its airport but we don't know that yet so
      # use plain Time objects rather than TimeWithZone objects here to make it easier to inject the timezone later.
      # rubocop:disable Rails/TimeZone
      start_date = Time.at(raw_event['StartDate'].match(EVENT_DATE_REGEX)[1].to_i / 1000)
      end_date = Time.at(raw_event['EndDate'].match(EVENT_DATE_REGEX)[1].to_i / 1000)

      start_time = Time.parse(raw_event['sTime'])
      end_time = Time.parse(raw_event['eTime'])

      # Combine the start/end date and time into one object
      start_date = start_date.change(hour: start_time.hour, min: start_time.min, sec: start_time.sec)
      end_date = end_date.change(hour: end_time.hour, min: end_time.min, sec: end_time.sec)

      return {
        name: raw_event['Title'],
        start_date: start_date,
        end_date: end_date,
        latitude: raw_event['Latitude'].to_f,
        longitude: raw_event['Longitude'].to_f,
        url: "https://eaa.org#{raw_event['EventUrl']}",
        city: raw_event['City'],
        state: raw_event['State'],
        digest: raw_event['ID'],
      }
      # rubocop:enable Rails/TimeZone
    rescue => error
      Rails.logger.info("Failed to parse EAA event: #{raw_event}")
      Sentry.capture_exception(error)
      return nil
    end
  end
end
