require 'test_helper'

class AirportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport, code: 'PAE')
  end

  test 'lists airports without cache' do
    get airports_path

    assert_response :success
    assert_equal @airport.code, JSON.parse(response.body).first['properties']['code'], 'Airport not included in airports index'
  end

  test 'lists airports with cache' do
    # Writing the GeoJSON dump to a file should result in a redirect to that asset rather than geenrating it dynamically
    AirportGeojsonDumper.new.write_to_file

    get airports_path
    assert_redirected_to AirportGeojsonDumper.cached
  end

  test 'new airport' do
    get new_airport_path(format: :drawer)
    assert_response :success, 'Failed to get new airport page'

    # There is no default format for this route
    assert_raises(ActionController::UnknownFormat) do
      get new_airport_path
    end
  end

  test 'create airport' do
    assert_difference('Airport.count') do
      assert_difference('Action.where(type: :airport_added).count') do
        assert_enqueued_with(job: AirportGeojsonDumperJob) do
          post airports_path(format: :js, params: {airport: {
            name: 'Unmapped airport',
            latitude: @airport.latitude,
            longitude: @airport.longitude,
            elevation: @airport.elevation,
            state: 'closed',
            landing_rights: :private_,
          }})

          assert_response :success
        end
      end
    end
  end

  test 'shows airport' do
    get airport_path(@airport)
    assert_response :success, 'Failed to get airport by ID'

    get airport_path(@airport.code)
    assert_response :success, 'Failed to get airport by code'

    get airport_path(@airport.code.downcase)
    assert_response :success, 'Failed to get airport by lowercase code'

    get airport_path("K#{@airport.code}")
    assert_response :success, 'Failed to get airport by ICAO code'

    get airport_path(@airport, format: :drawer)
    assert_response :success, 'Failed to get airport page as drawer'
  end

  test 'updates airport, unknown user' do
    with_versioning do
      assert_difference('Action.where(type: :airport_edited).count') do
        assert_difference('PaperTrail::Version.count') do
          # Updating an airport should create a new unknown user if not signed in
          assert_difference('Users::Unknown.count') do
            patch airport_path(@airport), params: {airport: {description: 'description'}}
            assert_redirected_to airport_path(@airport.code)
          end
        end
      end

      assert Users::User.find_by(id: @airport.versions.last.whodunnit).is_a?(Users::Unknown), 'Update version user not set to unknown user'

      # Updating again should not create another user
      assert_difference('Users::Unknown.count', 0) do
        patch airport_path(@airport), params: {airport: {description: 'description'}}
        assert_redirected_to airport_path(@airport.code)
      end

      assert_in_delta Time.zone.now, Users::Unknown.last.last_seen_at, 1.second, 'Unknown user\'s last seen at timestamp not set after updating airport'
      assert_in_delta Time.zone.now, Users::Unknown.last.last_edit_at, 1.second, 'Unknown user\'s last edit at timestamp not set after updating airport'
    end
  end

  test 'updates airport, known user' do
    user = create(:known)
    sign_in user

    # If there's a signed in user a new unknown user should not be created
    assert_difference('Users::Unknown.count', 0) do
      assert_difference('Action.where(type: :airport_edited).count') do
        # Not updating the tags should not trigger a GeoJSON dump
        assert_no_enqueued_jobs(only: AirportGeojsonDumperJob) do
          patch airport_path(@airport), params: {airport: {description: 'description'}}
          assert_redirected_to airport_path(@airport.code)
        end
      end
    end

    assert_in_delta Time.zone.now, user.reload.last_edit_at, 1.second, 'Known user\'s last edit timestamp not set after updating airport'
  end

  test 'updates airport photos' do
    assert_difference('@airport.contributed_photos.count', 1) do
      assert_difference('Action.where(type: :airport_photo_uploaded).count') do
        patch airport_path(@airport), params: {airport: {photos: [Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png')]}}
        assert_redirected_to airport_path(@airport.code)
      end
    end
  end

  test 'update airport tags' do
    assert_difference('Action.where(type: :tag_added).count') do
      # Updating the tags should trigger a GeoJSON dump
      assert_enqueued_with(job: AirportGeojsonDumperJob) do
        patch airport_path(@airport), params: {airport: {tags_attributes: {'0': {name: :camping, selected: true}}}}

        assert_redirected_to airport_path(@airport.code)
        assert_equal :camping, @airport.reload.tags.last.name, 'Did not save tag'
      end
    end
  end

  test 'rejects conflicting airport update' do
    with_versioning do
      @airport.update!(fuel_location: 'over there')

      # Updating a modified field after the page rendered timestamp should be rejected
      patch airport_path(@airport), params: {airport: {fuel_location: 'over here', rendered_at: 1.hour.ago}}
      assert_response :conflict

      # Updating an unmodified field after the page rendered timestamp however should be accepted
      patch airport_path(@airport), params: {airport: {description: 'neat airport', rendered_at: 1.hour.ago}}
      assert_redirected_to airport_path(@airport.code)

      # Updating a modified field in the future should be accepted field
      patch airport_path(@airport), params: {airport: {fuel_location: 'over here', rendered_at: 1.hour.from_now}}
      assert_redirected_to airport_path(@airport.code)
    end
  end

  test 'rejects update when airport is locked' do
    @airport.update!(locked_at: Time.zone.now)

    patch airport_path(@airport), params: {airport: {description: 'edit'}}
    assert_response :forbidden
  end

  test 'searches airports' do
    # Searching with the K prefix should drop it and return the same results as without it
    get search_airports_path(query: "K#{@airport.code}", latitude: @airport.latitude, longitude: @airport.longitude)

    assert_response :success
    assert_equal @airport.code, JSON.parse(response.body).first['code'], 'Airport not returned from search'
  end

  test 'history' do
    # Create a version to display as a sanity check
    with_versioning {@airport.update! description: 'Changed'}

    get history_airport_path(@airport)
    assert_response :success
  end

  test 'preview' do
    with_versioning do
      @airport.update! description: 'Changed'

      get preview_airport_path(@airport, version_id: @airport.versions.last)
      assert_response :success
    end
  end

  test 'revert' do
    sign_in create(:admin)

    with_versioning do
      original_description = @airport.description
      @airport.update! description: 'Changed'

      # Revert the update made above
      patch revert_airport_path(@airport, version_id: @airport.versions.last)
      assert_redirected_to airport_path(@airport.code)

      assert_equal original_description, @airport.reload.description, 'Airport not reverted to previous version'
    end
  end

  test 'annotations' do
    get annotations_airport_path(@airport)
    assert_response :success, 'Failed to get airport annotations'
    assert_equal @airport.annotations.length, JSON.parse(response.body).size, 'Incorrect number of annotations returned'
  end

  test 'uncached_photo_gallery' do
    # Initially uncached photos should be returned with a 200 response
    get uncached_photo_gallery_airport_path(@airport, params: {border: true})
    assert_response :success

    # After the external photos are updated the response should be a 204 to denote there's nothing new
    @airport.update!(external_photos_updated_at: Time.zone.now)
    get uncached_photo_gallery_airport_path(@airport)
    assert_response :no_content
  end
end
