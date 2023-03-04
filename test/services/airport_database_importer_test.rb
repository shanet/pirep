require 'test_helper'

class AirportDatabaseImporterTest < ActiveSupport::TestCase
  test 'import creates new airport' do
    AirportDatabaseImporter.new({parsed_airport[:airport_code] => parsed_airport}).load_database
    airport = Airport.last

    # Check relevant records were created
    assert_equal 1, Airport.count, 'Did not create new airport'
    assert_equal 2, airport.runways.count, 'Did not create runways for airport'
    assert_equal 2, airport.remarks.count, 'Did not create remarks for airport'

    # Check airport attributes created as expected
    assert_equal parsed_airport[:airport_code], airport.code
    assert_equal parsed_airport[:airport_name], airport.name
    assert_equal 'airport', airport.facility_type
    assert_equal parsed_airport[:facility_use], airport.facility_use
    assert_equal parsed_airport[:ownership_type], airport.ownership_type
    assert_equal parsed_airport[:latitude], airport.latitude
    assert_equal parsed_airport[:longitude], airport.longitude
    assert_equal ActiveRecord::Point.new(parsed_airport[:latitude], parsed_airport[:longitude]), airport.coordinates
    assert_equal parsed_airport[:elevation], airport.elevation
    assert_equal parsed_airport[:city], airport.city
    assert_equal parsed_airport[:state], airport.state
    assert_equal parsed_airport[:city_distance], airport.city_distance
    assert_equal parsed_airport[:fuel_types].split(','), airport.fuel_types
    assert_equal parsed_airport[:activation_date], airport.activation_date
    assert_equal :public_, airport.landing_rights
    assert_equal FaaApi.client.current_data_cycle(:airports), airport.faa_data_cycle
    assert_equal true, airport.bbox_checked
    assert_equal 48.8436501, airport.bbox_ne_latitude
    assert_equal(-117.2839675, airport.bbox_ne_longitude)
    assert_equal 48.8382765, airport.bbox_sw_latitude
    assert_equal(-117.2840137, airport.bbox_sw_longitude)

    # Check tags, runways, and remarks attributes created as expected
    assert_equal [:empty, :public_], airport.tags.order(:name).map(&:name), 'Did not create tags for new airport'

    airport.runways.each do |runway|
      assert runway.attributes.symbolize_keys.slice(:number, :length, :surface, :lights).in?(parsed_airport[:runways]), 'Did not create runway attributes for new airport'
    end

    airport.remarks.each do |remark|
      assert remark.attributes.symbolize_keys.slice(:element, :text).in?(parsed_airport[:remarks]), 'Did not create remark attributes for new airport'
    end
  end

  test 'import updates existing airport' do
    AirportDatabaseImporter.new({parsed_airport[:airport_code] => parsed_airport}).load_database
    airport = Airport.last

    # Set the FAA data cycle to something old to ensure it gets updated properly
    # Also clear the bounding box to ensure it doesn't get updated again
    airport.update!(faa_data_cycle: 1.month.ago, bbox_ne_latitude: nil, landing_rights: :restricted)

    assert_difference('Airport.count', 0) do
      assert_difference('Runway.count', 0) do
        assert_difference('Remark.count', 0) do
          assert_difference('Tag.count', 0) do
            AirportDatabaseImporter.new({parsed_airport[:airport_code] => parsed_airport(airport_name: 'New Airport Name')}).load_database

            # An existing airport should not have it's landing rights overwritten as they can be changed by users
            assert_equal :restricted, airport.reload.landing_rights, 'Overwrite landing rights on existing airport'
          end
        end
      end
    end

    airport = Airport.last

    assert_equal 'New Airport Name', airport.name, 'Airport name not updated on re-import'
    assert_equal FaaApi.client.current_data_cycle(:airports), airport.faa_data_cycle, 'Airport data cycle not updated on re-import'
    assert_not airport.closed?, 'Airport incorrectly marked as closed on re-import'
    assert_nil airport.bbox_ne_latitude, 'Airport bounding box incorrectly updated'
  end

  test 'tags closed airport' do
    AirportDatabaseImporter.new({parsed_airport[:airport_code] => parsed_airport}).load_database

    # Importing again with the airport having an old data cycle and  missing from the current data cycle should imply it has closed
    Airport.last.update!(faa_data_cycle: 1.month.ago)
    AirportDatabaseImporter.new({}).load_database

    assert Airport.last.closed?
  end

private

  def parsed_airport(**overrides)
    # Matches the expected output from parsing the airport data from the FAA database
    return {
      airport_code: 'PAE',
      airport_name: 'SNOHOMISH COUNTY (PAINE FLD)',
      facility_type: 'A',
      facility_use: 'PU',
      ownership_type: 'PU',
      latitude: 47.90731805555556,
      longitude: -122.2820938888889,
      elevation: 606,
      city: 'EVERETT',
      state: 'WA',
      city_distance: 6.0,
      sectional: 'SEATTLE',
      fuel_types: '100LL,A',
      activation_date: DateTime.new(1938, 11, 1),
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
    }.merge(overrides)
  end
end
