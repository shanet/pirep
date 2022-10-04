require 'test_helper'

class AirportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport, code: 'PAE')
  end

  test 'lists airports' do
    get airports_path

    assert_response :success
    assert_equal @airport.code, JSON.parse(response.body).first['properties']['code'], 'Airport not included in airports index'
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
  end

  test 'updates airport, unknown user' do
    with_versioning do
      # Updating an airport should create a new unknown user if not signed in
      assert_difference('PaperTrail::Version.count') do
        assert_difference('Users::Unknown.count') do
          patch airport_path(@airport), params: {airport: {description: 'description'}}
          assert_redirected_to airport_path(@airport.code)
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
      patch airport_path(@airport), params: {airport: {description: 'description'}}
      assert_redirected_to airport_path(@airport.code)
    end

    assert_in_delta Time.zone.now, user.reload.last_edit_at, 1.second, 'Known user\'s last edit timestamp not set after updating airport'
  end

  test 'updates airport photos' do
    assert_difference('@airport.photos.count', 1) do
      patch airport_path(@airport), params: {airport: {photos: [Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png')]}}
      assert_redirected_to airport_path(@airport.code)
    end
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
end
