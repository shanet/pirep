require 'test_helper'

class AirportDatabaseParserTest < ActiveSupport::TestCase
  test 'parses airport data archive from FAA' do
    airports = AirportDatabaseParser.new.download_and_parse
    assert_equal expected_airport_data, airports, 'Parsed airport data did not match expected data'
  end

private

  def expected_airport_data
    return {
      '26210.*A' => {
        airport_code: 'PAE',
        airport_name: 'SNOHOMISH COUNTY (PAINE FLD)',
        facility_type: 'AIRPORT',
        facility_use: 'PU',
        ownership_type: 'PU',
        owner_name: 'SNOHOMISH COUNTY',
        owner_phone: '425-388-3411',
        latitude: 47.9073174,
        longitude: -122.282094,
        elevation: '607.5',
        fuel_type: '100LLA',
        runways: [
          {
            number: '16L/34R',
            length: '3004',
            surface: 'ASPH-G',
            lights: 'MED',
          },
          {
            number: '16R/34L',
            length: '9010',
            surface: 'ASPH-CONC-G',
            lights: 'HIGH',
          },
        ],
        remarks: [
          {
            element: 'WAA110-1',
            text: 'RWY 16L/34R CLSD BTN 0500-1500Z.',
          },
          {
            element: 'WAA110-11',
            text: 'AVOID INT DEPS FM RWY 16L/34R',
          },
        ],
      },
    }
  end
end
