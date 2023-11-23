require 'test_helper'

class OurAirportsDatabaseParserTest < ActiveSupport::TestCase
  test 'parses airport data archive from OurAirports' do
    airports = OurAirportsDatabaseParser.new.download_and_parse
    assert_equal expected_airport_data, airports, 'Parsed airport data did not match expected data'
  end

  test 'ignores closed airports' do
    airports = OurAirportsDatabaseParser.new.download_and_parse
    assert_nil airports['CA-0077'], 'Included closed airport'
  end

  test 'ignores non-Canadian airports' do
    airports = OurAirportsDatabaseParser.new.download_and_parse
    assert_nil airports['KPAE'], 'Included US airport'
  end

private

  def expected_airport_data(**overrides)
    return {
      'CYRV' => {
        our_airports_id: '1896',
        airport_name: 'Revelstoke Airport',
        icao_code: 'CYRV',
        facility_type: 'airport',
        facility_use: 'PU',
        ownership_type: 'PU',
        latitude: 50.962245,
        longitude: -118.184258,
        elevation: 1459,
        city: 'REVELSTOKE',
        state: 'British Columbia',
        country: 'ca',
        city_distance: nil,
        sectional: nil,
        fuel_types: nil,
        activation_date: nil,
        data_source: :our_airports,
        runways: [{
          number: '12/30',
          length: 4800,
          surface: 'ASP',
          lights: 'false',
        }],
      }.merge(overrides),
    }
  end
end
