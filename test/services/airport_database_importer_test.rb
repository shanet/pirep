require 'test_helper'

class AirportDatabaseImporterTest < ActiveSupport::TestCase
  test 'import creates new airport' do
    AirportDatabaseImporter.new({parsed_airport[:site_number] => parsed_airport}).load_database
    airport = Airport.last

    # Check relevant records were created
    assert_equal 1, Airport.count, 'Did not create new airport'
    assert_equal 2, airport.runways.count, 'Did not create runways for airport'
    assert_equal 2, airport.remarks.count, 'Did not create remarks for airport'

    # Check airport attributes created as expected
    assert_equal parsed_airport[:site_number], airport.site_number
    assert_equal parsed_airport[:airport_code], airport.code
    assert_equal parsed_airport[:airport_name], airport.name
    assert_equal parsed_airport[:facility_type].downcase, airport.facility_type
    assert_equal parsed_airport[:facility_use], airport.facility_use
    assert_equal parsed_airport[:ownership_type], airport.ownership_type
    assert_equal parsed_airport[:owner_name], airport.owner_name
    assert_equal parsed_airport[:owner_phone], airport.owner_phone
    assert_equal parsed_airport[:latitude], airport.latitude
    assert_equal parsed_airport[:longitude], airport.longitude
    assert_equal ActiveRecord::Point.new(parsed_airport[:latitude], parsed_airport[:longitude]), airport.coordinates
    assert_equal parsed_airport[:elevation], airport.elevation
    assert_equal parsed_airport[:fuel_type], airport.fuel_type
    assert_equal :public_, airport.landing_rights
    assert_equal FaaApi.client.current_data_cycle, airport.faa_data_cycle

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
    AirportDatabaseImporter.new({parsed_airport[:site_number] => parsed_airport}).load_database

    # Set the FAA data cycle to something old to ensure it gets updated properly
    Airport.last.update!(faa_data_cycle: 1.month.ago)

    assert_difference('Airport.count', 0) do
      assert_difference('Runway.count', 0) do
        assert_difference('Remark.count', 0) do
          AirportDatabaseImporter.new({parsed_airport[:site_number] => parsed_airport(airport_name: 'New Airport Name')}).load_database
        end
      end
    end

    airport = Airport.last

    assert_equal 'New Airport Name', airport.name, 'Airport name not updated on re-import'
    assert_equal FaaApi.client.current_data_cycle, airport.faa_data_cycle, 'Airport data cycle not updated on re-import'
    assert_not airport.closed?, 'Airport incorrectly marked as closed on re-import'
  end

  test 'tags closed airport' do
    AirportDatabaseImporter.new({parsed_airport[:site_number] => parsed_airport}).load_database

    # Importing again with the airport having an old data cycle and  missing from the current data cycle should imply it has closed
    Airport.last.update!(faa_data_cycle: 1.month.ago)
    AirportDatabaseImporter.new({}).load_database

    assert Airport.last.closed?
  end

  test 'imports airport with changed site number' do
    AirportDatabaseImporter.new({parsed_airport[:site_number] => parsed_airport}).load_database

    # Importing with a different site number should fallback to matching on airport code and not create a new airport
    assert_difference('Airport.count', 0) do
      airport = parsed_airport(site_number: 42)
      AirportDatabaseImporter.new({airport[:site_number] => airport}).load_database
    end

    # Importing with a different site number and airport code should create a new airport
    assert_difference('Airport.count') do
      airport = parsed_airport(site_number: 43, airport_code: 'SEA')
      AirportDatabaseImporter.new({airport[:site_number] => airport}).load_database
    end
  end

private

  def parsed_airport(**overrides)
    # Matches the expected output from parsing the airport data from the FAA database
    return {
      site_number: '26210.*A',
      airport_code: 'PAE',
      airport_name: 'SNOHOMISH COUNTY (PAINE FLD)',
      facility_type: 'airport',
      facility_use: 'PU',
      ownership_type: 'PU',
      owner_name: 'SNOHOMISH COUNTY',
      owner_phone: '425-388-3411',
      latitude: 47.9073174,
      longitude: -122.282094,
      elevation: 607,
      fuel_type: '100LLA',
      runways: [
        {
          number: '16L/34R',
          length: 3004,
          surface: 'ASPH-G',
          lights: 'MED',
        },
        {
          number: '16R/34L',
          length: 9010,
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
    }.merge(overrides)
  end
end
