require 'google/google_api'

class AirportTimezoneProvider
  def initialize
    @client = GoogleApi.client
  end

  def timezone(airport)
    return @client.timezone(airport.latitude, airport.longitude)
  end
end
