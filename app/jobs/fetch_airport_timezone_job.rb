class FetchAirportTimezoneJob < ApplicationJob
  def perform(airport)
    timezone = AirportTimezoneProvider.new.timezone(airport)
    airport.update!(timezone: timezone, timezone_checked_at: Time.zone.now)
  end
end
