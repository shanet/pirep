require 'test_helper'

class FaaAirportDatabaseParserTest < ActiveSupport::TestCase
  test 'parses airport data archive from FAA' do
    airports = FaaAirportDatabaseParser.new.download_and_parse
    assert_equal expected_airport_data, airports, 'Parsed airport data did not match expected data'
  end

private

  def expected_airport_data
    return {
      'PAE' => {
        airport_name: 'SNOHOMISH COUNTY (PAINE FLD)',
        icao_code: 'KPAE',
        facility_type: 'airport',
        facility_use: 'PU',
        ownership_type: 'PU',
        latitude: 47.90731805555556,
        longitude: -122.2820938888889,
        elevation: 606,
        city: 'EVERETT',
        state: 'WA',
        country: :us,
        city_distance: 6.0,
        sectional: 'SEATTLE',
        fuel_types: '100LL,A',
        activation_date: DateTime.new(1938, 11, 1),
        data_source: :faa,
        runways: [
          {
            number: '16L/34R',
            length: 3004,
            surface: 'ASPH',
            lights: 'MED',
          },
          {
            number: '16R/34L',
            length: 9010,
            surface: 'ASPH-CONC',
            lights: 'HIGH',
          },
        ],
        remarks: [
          {
            element: 'E111',
            text: 'ESTABD PRIOR TO 15 MAY 1959.',
          },
          {
            element: 'A110-1',
            text: 'RWY 16L/34R CLSD BTN 0500-1500Z.',
          },
        ],
      },
    }
  end
end
