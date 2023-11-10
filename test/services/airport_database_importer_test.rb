require 'test_helper'

class AirportDatabaseImporterTest < ActiveSupport::TestCase
  setup do
    @faa_airport = faa_airport_fixture
    @our_airports_airport = our_airports_airport_fixture

    @airports = {
      @faa_airport[:airport_code] => @faa_airport,
      @our_airports_airport[:airport_code] => @our_airports_airport,
    }
  end

  test 'import creates new airports' do
    AirportDatabaseImporter.new(@airports).import!

    faa_airport = Airport.find_by(data_source: 'faa')
    our_airports_airport = Airport.find_by(data_source: 'our_airports')

    # Check relevant records were created
    assert_equal 2, Airport.count, 'Did not create new airports'
    assert_equal 3, (faa_airport.runways.count + our_airports_airport.runways.count), 'Did not create runways for airports'
    assert_equal 2, (faa_airport.remarks.count + our_airports_airport.remarks.count), 'Did not create remarks for airports'

    # Check airport attributes created as expected
    assert_equal @faa_airport[:airport_code], faa_airport.code
    assert_equal @faa_airport[:airport_name], faa_airport.name
    assert_equal @faa_airport[:icao_code], faa_airport.icao_code
    assert_equal 'airport', faa_airport.facility_type
    assert_equal @faa_airport[:facility_use], faa_airport.facility_use
    assert_equal @faa_airport[:ownership_type], faa_airport.ownership_type
    assert_equal @faa_airport[:latitude], faa_airport.latitude
    assert_equal @faa_airport[:longitude], faa_airport.longitude
    assert_equal ActiveRecord::Point.new(@faa_airport[:latitude], @faa_airport[:longitude]), faa_airport.coordinates
    assert_equal @faa_airport[:elevation], faa_airport.elevation
    assert_equal @faa_airport[:city], faa_airport.city
    assert_equal @faa_airport[:state], faa_airport.state
    assert_equal @faa_airport[:country], faa_airport.country
    assert_equal @faa_airport[:city_distance], faa_airport.city_distance
    assert_equal @faa_airport[:fuel_types].split(','), faa_airport.fuel_types
    assert_equal @faa_airport[:activation_date], faa_airport.activation_date
    assert_equal @faa_airport[:data_source], faa_airport.data_source
    assert_equal :public_, faa_airport.landing_rights
    assert_equal FaaApi.client.current_data_cycle(:airports), faa_airport.faa_data_cycle
    assert_equal true, faa_airport.bbox_checked
    assert_equal 48.8436501, faa_airport.bbox_ne_latitude
    assert_equal(-117.2839675, faa_airport.bbox_ne_longitude)
    assert_equal 48.8382765, faa_airport.bbox_sw_latitude
    assert_equal(-117.2840137, faa_airport.bbox_sw_longitude)
    assert_equal 'America/Los_Angeles', faa_airport.timezone
    assert_in_delta Time.zone.now, faa_airport.timezone_checked_at, 1.minute

    assert_equal @our_airports_airport[:airport_code], our_airports_airport.code
    assert_equal @our_airports_airport[:airport_name], our_airports_airport.name
    assert_equal @our_airports_airport[:icao_code], our_airports_airport.icao_code
    assert_equal 'airport', our_airports_airport.facility_type
    assert_equal @our_airports_airport[:facility_use], our_airports_airport.facility_use
    assert_equal @our_airports_airport[:ownership_type], our_airports_airport.ownership_type
    assert_equal @our_airports_airport[:latitude], our_airports_airport.latitude
    assert_equal @our_airports_airport[:longitude], our_airports_airport.longitude
    assert_equal ActiveRecord::Point.new(@our_airports_airport[:latitude], @our_airports_airport[:longitude]), our_airports_airport.coordinates
    assert_equal @our_airports_airport[:elevation], our_airports_airport.elevation
    assert_equal @our_airports_airport[:city], our_airports_airport.city
    assert_equal @our_airports_airport[:state], our_airports_airport.state
    assert_equal @our_airports_airport[:country], our_airports_airport.country
    assert_nil our_airports_airport.city_distance
    assert_nil our_airports_airport.fuel_types
    assert_nil our_airports_airport.activation_date
    assert_equal @our_airports_airport[:data_source], our_airports_airport.data_source
    assert_equal :public_, our_airports_airport.landing_rights
    assert_equal FaaApi.client.current_data_cycle(:airports), our_airports_airport.faa_data_cycle
    assert_equal true, our_airports_airport.bbox_checked
    assert_equal 48.8436501, our_airports_airport.bbox_ne_latitude
    assert_equal(-117.2839675, our_airports_airport.bbox_ne_longitude)
    assert_equal 48.8382765, our_airports_airport.bbox_sw_latitude
    assert_equal(-117.2840137, our_airports_airport.bbox_sw_longitude)
    assert_equal 'America/Los_Angeles', our_airports_airport.timezone
    assert_in_delta Time.zone.now, our_airports_airport.timezone_checked_at, 1.minute

    # Check tags, runways, and remarks attributes created as expected
    assert_equal [:empty, :public_], faa_airport.tags.order(:name).map(&:name), 'Did not create tags for new airport'

    faa_airport.runways.each do |runway|
      assert runway.attributes.symbolize_keys.slice(:number, :length, :surface, :lights).in?(@faa_airport[:runways]), 'Did not create runway attributes for new airport'
    end

    faa_airport.remarks.each do |remark|
      assert remark.attributes.symbolize_keys.slice(:element, :text).in?(@faa_airport[:remarks]), 'Did not create remark attributes for new airport'
    end
  end

  test 'import updates existing airport' do
    AirportDatabaseImporter.new(@airports).import!

    # Set the FAA data cycle to something old to ensure it gets updated properly
    # Also clear the bounding box & timezone to ensure they don't get updated again
    airport = Airport.find_by(data_source: 'faa')
    airport.update!(faa_data_cycle: 1.month.ago, bbox_ne_latitude: nil, timezone: nil, landing_rights: :restricted)

    assert_difference('Airport.count', 0) do
      assert_difference('Runway.count', 0) do
        assert_difference('Remark.count', 0) do
          assert_difference('Tag.count', 0) do
            @faa_airport[:airport_name] = 'New Airport Name'
            AirportDatabaseImporter.new(@airports).import!

            # An existing airport should not have it's landing rights overwritten as they can be changed by users
            assert_equal :restricted, airport.reload.landing_rights, 'Overwrote landing rights on existing airport'
          end
        end
      end
    end

    airport = Airport.find_by(data_source: 'faa')

    assert_equal 'New Airport Name', airport.name, 'Airport name not updated on re-import'
    assert_equal FaaApi.client.current_data_cycle(:airports), airport.faa_data_cycle, 'Airport data cycle not updated on re-import'
    assert_not airport.closed?, 'Airport incorrectly marked as closed on re-import'
    assert_nil airport.bbox_ne_latitude, 'Airport bounding box incorrectly updated'
    assert_nil airport[:timezone], 'Airport timezone incorrectly updated'
  end

  test 'tags closed airport' do
    AirportDatabaseImporter.new(@airports).import!
    airport = Airport.find_by(data_source: 'faa')

    # Importing again with the airport having an old data cycle and  missing from the current data cycle should imply it has closed
    airport.update!(faa_data_cycle: 1.month.ago)
    AirportDatabaseImporter.new({}).import!

    assert airport.closed?
  end

  test 'does not import airport with conflicting data sources' do
    AirportDatabaseImporter.new(@airports).import!

    # The name should not be updated if the data source conflicts with the existing data source
    @faa_airport[:airport_name] = 'New Airport Name'
    @faa_airport[:data_source] = :our_airports
    AirportDatabaseImporter.new(@airports).import!

    airport = Airport.find_by(data_source: 'faa')
    assert_equal faa_airport_fixture[:airport_name], airport.name, 'Airport updated from different data source'
  end

private

  def faa_airport_fixture(**overrides)
    # Matches the expected output from parsing the airport data from the FAA database
    return {
      airport_code: 'PAE',
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
      country: 'us',
      city_distance: 6.0,
      sectional: 'SEATTLE',
      fuel_types: '100LL,A',
      activation_date: DateTime.new(1938, 11, 1),
      data_source: 'faa',
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

  def our_airports_airport_fixture(**overrides)
    # Matches the expected output from parsing the airport data from the FAA database
    return {
      airport_code: 'CYRV',
      airport_name: 'Revelstoke Airport',
      icao_code: 'CYRV',
      facility_type: 'airport',
      facility_use: 'PU',
      ownership_type: 'PU',
      latitude: 50.962245,
      longitude: -118.184258,
      elevation: 1459,
      city: 'Revelstoke',
      state: 'British Columbia',
      country: 'ca',
      city_distance: nil,
      sectional: nil,
      fuel_types: nil,
      activation_date: nil,
      data_source: 'our_airports',
      our_airports_id: '1896',
      runways: [{
        number: '12/30',
        length: 4800,
        surface: 'ASP',
        lights: 'false',
      }],
    }.merge(overrides)
  end
end
