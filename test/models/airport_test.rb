require 'test_helper'

class AirportTest < ActiveSupport::TestCase
  setup do
    @airport = create(:airport)
  end

  test 'populates new unmapped airport' do
    airport = Airport.new_unmapped(attributes_for(:airport, landing_rights: :restricted))
    airport.save!

    assert_equal 'UNM01', airport.code
    assert_equal 'airport', airport.facility_type
    assert_equal 'PR', airport.facility_use
    assert_equal 'PR', airport.ownership_type
    assert_equal :restricted, airport.landing_rights
    assert_equal 'user_contributed', airport.data_source

    assert :unmapped.in?(airport.tags.map(&:name)), 'Unmapped airport not tagged as such'
    assert :restricted.in?(airport.tags.map(&:name)), 'Unmapped airport not tagged restricted'

    # Creating another unmapped airport should use the next unmapped airport code
    airport2 = Airport.new_unmapped(attributes_for(:airport, landing_rights: nil))
    airport2.save!

    assert_equal 'UNM02', airport2.code, 'Unmapped airport not given a unique code'
    assert_equal :private_, airport2.landing_rights, 'Unmapped airport did not default to private landing rights'

    # Deleting the first airport should still create a code with the next largest number
    airport.destroy!

    airport3 = Airport.new_unmapped(attributes_for(:airport, landing_rights: nil))
    airport3.save!
    assert_equal 'UNM03', airport3.code, 'Unmapped airport not given a unique code'
  end

  test 'does not return hidden facility types' do
    assert_not Airport.facility_types.keys.include?(:ultralight), 'Included hidden facility type'
  end

  test 'renders geojson' do
    expected_geojson = {
      id: @airport.code_digest,
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [@airport.longitude, @airport.latitude],
      },
      properties: {
        code: @airport.code,
        tags: ['public_', 'populated'],
        facility_type: 'airport',
      },
    }

    assert_equal expected_geojson, @airport.to_geojson, 'Generated geojson for airport differs from expected'
  end

  test 'is empty' do
    assert create(:airport, :empty).empty?, 'Airport not empty'
  end

  test 'is closed' do
    airport = create(:airport, :closed)
    assert airport.closed?, 'Airport not closed'
  end

  test 'is unmapped' do
    assert_not @airport.unmapped?, 'Mapped airport considered unmapped'
    @airport.tags << create(:tag, name: :unmapped)
    assert @airport.unmapped?, 'Unmapped airport not considered unmapped'
  end

  test 'is featured' do
    airport = create(:airport, :featured)
    assert airport.featured?, 'Airport not featured'
  end

  test 'authoritative data source' do
    assert create(:airport, data_source: :faa).authoritative?, 'FAA airport not authoritative'
    assert_not create(:airport, data_source: :our_airports).authoritative?, 'Our Airports airport authoritative'
    assert_not create(:airport, data_source: :user_contributed).authoritative?, 'User contributed airport authoritative'
  end

  test 'airport is not empty if tagged with a user addable tag' do
    airport = create(:airport, :empty)
    assert airport.empty?, 'Airport empty with associated non-user addable tag'

    airport.tags << create(:tag, name: :food, airport: airport)
    assert_not airport.empty?, 'Airport empty with associated user addable tag'
  end

  test 'airport is not empty if landing rights are added' do
    airport = create(:airport, :empty)
    airport.update!(landing_rights: :restricted)
    assert_not airport.empty?, 'Airport not empty with landing rights added'
  end

  test 'airport is not empty if description added' do
    airport = create(:airport, :empty)
    airport.update!(description: 'description')
    assert_not airport.empty?, 'Airport not empty with description field added'
  end

  test 'airport is not empty if annotation added' do
    airport = create(:airport, :empty)
    airport.update!(annotations: [{'label' => 'foo', 'latitude' => 48.0, 'longitude' => -122.0}])
    assert_not airport.empty?, 'Airport not empty with annotation added'
  end

  test 'removes empty tag when no longer empty' do
    airport = create(:airport, :empty)

    # Adding a description should make the airport non-empty and remove the empty tag on save
    assert airport.empty?
    airport.update!(description: 'description')
    assert_not airport.reload.tags.map(&:name).include?(:empty), 'Empty tag not removed from airport'
  end

  test 'updates tags when landing rights change' do
    airport = create(:airport)
    assert airport.tags.has?(:public_), 'Public tag not added to airport'
    assert_not airport.tags.has?(:restricted_), 'Restricted tag added to airport'
    assert_not airport.tags.has?(:private_), 'Private tag added to airport'

    airport.update!(landing_rights: :restricted)
    airport = airport.reload
    assert airport.tags.has?(:restricted), 'Restricted tag not added to airport'
    assert_not airport.tags.has?(:public_), 'Public tag added to airport'
    assert_not airport.tags.has?(:private_), 'Private tag added to airport'

    airport.update!(landing_rights: :private_)
    airport = airport.reload
    assert airport.tags.has?(:private_), 'Private tag not added to airport'
    assert_not airport.tags.has?(:restricted_), 'Restricted tag added to airport'
    assert_not airport.tags.has?(:public_), 'Public tag added to airport'
  end

  test 'unselected tag names' do
    tag = create(:tag, airport: @airport)
    @airport.tags << tag
    assert_not @airport.unselected_tag_names.include?(tag.name), 'Added tag included into unselected tag list'
  end

  test 'collates versions when history-enabled column is changed' do
    assert_enqueued_with(job: VersionsCollatorJob) do
      @airport.update(description: 'changed')
    end

    # Reset the changes above so the [column]_previously_changed? methods return false
    @airport.reload

    assert_no_enqueued_jobs(only: VersionsCollatorJob) do
      @airport.update!(faa_data_cycle: Time.zone.now)
    end
  end

  test 'elevation threat level' do
    elevations = [
      [-1000, 'green'],
      [2999, 'green'],
      [3000, 'orange'],
      [4999, 'orange'],
      [5000, 'red'],
      [10_000, 'red'],
    ]

    elevations.each do |elevation|
      @airport.update! elevation: elevation.first
      assert_equal elevation.last, @airport.elevation_threat_level, 'Unexpected elevation threat level for %s' % elevation.first
    end
  end

  test 'gets uncached external photos' do
    assert_enqueued_with(job: AirportPhotosCacherJob) do
      uncached_photos = @airport.uncached_external_photos

      assert uncached_photos.is_a?(Array), 'Uncached photos not returned'
      assert uncached_photos.first[:url].present?, 'Uncached photo URL not returned'
      assert uncached_photos.first[:attribution].present?, 'Uncached photo attribution not returned'
    end
  end

  test 'does not cache external photos twice' do
    assert_enqueued_with(job: AirportPhotosCacherJob) do
      @airport.uncached_external_photos

      assert_no_enqueued_jobs do
        @airport.uncached_external_photos
      end

      # It should enqueue a job beyond the timeout period
      travel(11.minutes) do
        assert_enqueued_with(job: AirportPhotosCacherJob) do
          @airport.uncached_external_photos
        end
      end
    end
  end

  test 'puts contributed photos before external photos' do
    assert_equal :featured, @airport.all_photos.keys.first, 'Featured photo not first'
    assert_equal :contributed, @airport.all_photos.keys.second, 'Contributed photos not second'
    assert_equal :external, @airport.all_photos.keys.last, 'External photos not last'
  end

  test 'has featured photo' do
    # By default the featured photo should be an empty array if missing
    assert @airport.all_photos[:featured].empty?

    @airport.update!(featured_photo: @airport.contributed_photos.first)
    assert_equal 1, @airport.all_photos[:featured].count, 'Featured photo not returned'
    assert_equal @airport.contributed_photos.first, @airport.all_photos[:featured].first, 'Featured photo not first'

    # Removing the photo should also clear the featured photo
    @airport.contributed_photos.purge
    assert @airport.all_photos[:featured].empty?, 'Featured photo set after deletion'
  end

  test 'has customized photo key' do
    assert_match(/uploads\/airport_photos\/contributed\/#{@airport.code.downcase}\/.+.png/, @airport.contributed_photos.first.key, 'Unexpected airport photo customized key')
  end

  test 'has correct theme' do
    # The theme is based on the airport code so set it to something specific first
    @airport.update!(code: 'PAE')

    assert_equal 'green', @airport.theme, 'Unexpected theme color for airport'
  end

  test 'has all relevant versions' do
    with_versioning do
      # The airport should have versions for its associated tags so create & destroy one to create some versions
      @airport.update!(description: 'updated')
      webcam = create(:webcam, airport: @airport)
      tag = create(:tag, airport: @airport)
      tag.destroy!

      assert_equal 5, @airport.all_versions.count, 'Airport does not have own versions and associated tag versions'

      (tag.versions + webcam.versions).each do |version|
        assert version.in?(@airport.all_versions), 'Tag/webcam versions not included with airport versions'
      end
    end
  end

  test 'has created by user' do
    # Check we handle nil whodunnit values for the version since nearly all airports won't have a created by user
    assert_nil @airport.created_by

    with_versioning do
      user = create(:unknown)
      airport = create(:airport)
      airport.versions.first.update!(whodunnit: user.id)

      assert_equal user, airport.created_by, 'Wrong user created airport'
    end
  end

  test 'deserializes coordinates as point type' do
    with_versioning do
      @airport.update!(description: 'changed')
      assert @airport.versions.last.reify.coordinates.is_a?(ActiveRecord::Point), 'Coordinates not deserialized as point'
    end
  end

  test 'uses bounding box' do
    # Heliports don't use bounding boxes
    assert_not create(:airport, facility_type: 'heliport').uses_bounding_box?, 'Heliport uses bounding box'
  end

  test 'has bounding box' do
    assert @airport.has_bounding_box?, 'Airport does not have bounding box'
    assert_not create(:airport, :no_bounding_box).has_bounding_box?, 'Airport has bounding box'
    assert_nil create(:airport, :no_bounding_box).bounding_box, 'Airport has bounding box'
    assert_not create(:airport, facility_type: 'heliport').has_bounding_box?, 'Heliport uses bounding box'
  end

  test 'has weather' do
    assert_not @airport.has_weather?, 'Airport without METAR has weather'

    create(:metar, airport: @airport)
    assert @airport.reload.has_weather?, 'Airport with METAR does not have weather'

    @airport.metar.update!(created_at: 1.day.ago)
    assert_not @airport.reload.has_weather?, 'Airport with stale METAR has weather'
  end

  test 'converts fuel types to array' do
    @airport.fuel_types = 'A , MOGAS'
    assert_equal ['A', 'MOGAS'], @airport.fuel_types, 'Fuel types string not conver to array and stripped of whitespace'
  end

  test 'converts annotations to array' do
    @airport.annotations = '[{"label": "foo", "latitude": 48.0, "longitude": -122.0}]'
    assert_equal [{'label' => 'foo', 'latitude' => 48.0, 'longitude' => -122.0}], @airport.annotations, 'Annotations JSON string not parsed'

    @airport.annotations = []
    assert_nil @airport.annotations, 'Empty annotations array not set to nil'
  end

  test 'rejects photos with non-image content type' do
    @airport.contributed_photos.first.blob.update!(content_type: 'application/octet-stream')

    assert_not @airport.valid?, 'Accepted non-image attachment'
    assert @airport.errors[:contributed_photos].present?, 'Did not set contributed photos error message'
  end

  test 'rejects photos with large file size' do
    @airport.contributed_photos.first.blob.update!(byte_size: 5.1.megabytes)

    assert_not @airport.valid?, 'Accepted large image attachment'
    assert @airport.errors[:contributed_photos].present?, 'Did not set contributed photos error message'
  end

  test 'has updated_at timestamps for editable fields' do
    with_versioning do
      assert_nil @airport.description_updated_at, 'Timestamp returned for never updated field'

      # Create an earlier version to ensure we're getting the latest version's timestamp
      travel_to(1.month.ago) do
        @airport.update!(description: 'foobar1')
      end

      freeze_time do
        @airport.update!(description: 'foobar2')
        assert_in_delta Time.zone.now, @airport.description_updated_at, 1.second, 'Timestamp not returned for updated field'
      end
    end
  end

  test 'timezone' do
    airport = create(:airport, timezone: nil)
    assert_equal Rails.configuration.time_zone, airport.timezone, 'Did not fallback to default timezone'
  end

  test 'complementary airports' do
    airport = create(:airport, tags: [create(:tag, name: :food), create(:tag, name: :lodging), create(:tag, name: :fishing), create(:tag, name: :events)])

    # Airports with shared but non-addable tags should not be complementary
    create(:airport, tags: [create(:tag, name: :events)])

    # Airports with non-shared tags should not be complementary
    create(:airport, tags: [create(:tag, name: :camping)])

    complementary_airport = create(:airport, tags: [create(:tag, name: :lodging)])

    complementary_close_airport = create(:airport, latitude: airport.latitude + 1, longitude: airport.longitude + 1,
                                                   tags: [create(:tag, name: :food), create(:tag, name: :lodging), create(:tag, name: :golfing)])

    complementary_far_airport = create(:airport, latitude: airport.latitude + 10, longitude: airport.longitude + 10,
                                                 tags: [create(:tag, name: :food), create(:tag, name: :lodging), create(:tag, name: :golfing)])

    # Complementary airports should be ordered first by number of intersecting tags and then by promximity
    assert_equal [complementary_close_airport, complementary_far_airport, complementary_airport], airport.complements, 'Unexpected complementary airports'

    assert_equal [], create(:airport, tags: []).complements, 'Empty airport had complementary airports'
  end

  test 'has tag?' do
    airport = create(:airport, tags: [create(:tag, name: :food)])
    assert airport.tags.has?(:food), 'Did not find existing tag'
    assert_not airport.tags.has?(:private_), 'Found non-existant tag'
  end

  test 'becomes featured' do
    assert_not @airport.featured?, 'Non-featured airport featured'

    # Adding one more field should make the airport featured
    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      @airport.update!(landing_requirements: 'foobar')
      assert @airport.featured?, 'Airport not marked as featured'
    end

    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      @airport.update!(landing_requirements: nil)
      assert_not @airport.featured?, 'Non-featured airport featured'
    end
  end
end
