require 'test_helper'

class Manage::AirportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport)
    sign_in :admin
  end

  test 'index' do
    get manage_airports_path
    assert_response :success
  end

  test 'search' do
    get search_manage_airports_path(query: @airport.code)
    assert_response :success
  end

  test 'show' do
    get manage_airport_path(@airport)
    assert_response :success
  end

  test 'edit' do
    get edit_manage_airport_path(@airport)
    assert_response :success
  end

  test 'update' do
    patch manage_airport_path(@airport, params: {airport: {name: 'foo'}})
    assert_redirected_to manage_airport_path(@airport)
  end

  test 'destroy' do
    assert_difference('Airport.count', -1) do
      delete manage_airport_path(@airport)
      assert_redirected_to manage_airports_path
    end
  end

  test 'destroy_attachment' do
    assert_difference('ActiveStorage::Attachment.count', -1) do
      delete destroy_attachment_manage_airport_path(@airport, type: :contributed_photos, attachment_id: @airport.contributed_photos.first.id)
      assert_redirected_to manage_airport_path(@airport)
    end
  end

  test 'update_version' do
    with_versioning do
      @airport.update!(description: 'making a version')

      patch version_manage_airport_path(@airport, @airport.versions.last.id), params: {version: {reviewed_at: Time.zone.now}}
      assert_redirected_to history_airport_path(@airport)

      assert_in_delta Time.zone.now, @airport.versions.last.reviewed_at, 3.seconds, 'Version not set as reviewed'
    end
  end
end
