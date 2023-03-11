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

    assert :unmapped.in?(airport.tags.map(&:name)), 'Unmapped airport not tagged as such'
    assert :restricted.in?(airport.tags.map(&:name)), 'Unmapped airport not tagged restricted'

    # Creating another unmapped airport should use the next unmapped airport code
    airport2 = Airport.new_unmapped(attributes_for(:airport, landing_rights: nil))
    airport2.save!

    assert_equal 'UNM02', airport2.code, 'Unmapped airport not given a unique code'
    assert_equal :private_, airport2.landing_rights, 'Unmapped airport did not default to private landing rights'
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

  test 'airport is empty' do
    assert create(:airport, :empty).empty?, 'Airport not empty'
  end

  test 'airport is closed' do
    airport = create(:airport)
    create(:tag, airport: airport, name: :closed)

    assert airport.closed?, 'Airport not closed'
  end

  test 'is unmapped' do
    assert_not @airport.unmapped?, 'Mapped airport considered unmapped'
    @airport.tags << create(:tag, name: :unmapped)
    assert @airport.unmapped?, 'Unmapped airport not considered unmapped'
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

  test 'removes empty tag when no longer empty' do
    airport = create(:airport, :empty)

    # Adding a description should make the airport non-empty and remove the empty tag on save
    assert airport.empty?
    airport.update!(description: 'description')
    assert_not airport.reload.tags.map(&:name).include?(:empty), 'Empty tag not removed from airport'
  end

  test 'updates tags when landing rights change' do
    airport = create(:airport)
    assert_equal 1, airport.tags.count, 'Airport has multiple tags'
    assert_equal :public_, airport.tags.first.name, 'Public tag not added to airport'

    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      airport.update!(landing_rights: :restricted)
      airport = airport.reload
      assert_equal 1, airport.tags.count, 'Airport has multiple tags'
      assert_equal :restricted, airport.tags.first.name, 'Public tag not added to airport'
    end

    assert_enqueued_with(job: AirportGeojsonDumperJob) do
      airport.update!(landing_rights: :private_)
      airport = airport.reload
      assert_equal 1, airport.tags.count, 'Airport has multiple tags'
      assert_equal :private_, airport.tags.first.name, 'Public tag not added to airport'
    end
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
      tag = create(:tag, airport: @airport)
      tag.destroy!

      assert_equal 3, @airport.all_versions.count, 'Airport does not have own versions and associated tag versions'

      tag.versions.each do |version|
        assert version.in?(@airport.all_versions), 'Tag versions not included with airport versions'
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

  test 'converts fuel types to array' do
    @airport.fuel_types = 'A , MOGAS'
    assert_equal ['A', 'MOGAS'], @airport.fuel_types, 'Fuel types string not conver to array and stripped of whitespace'
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
end
