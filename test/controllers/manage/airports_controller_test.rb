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

  test 'analytics' do
    # With no pageviews
    get analytics_manage_airport_path(@airport)
    assert_response :success

    # With pageviews
    create(:pageview, record: @airport)
    get analytics_manage_airport_path(@airport)
    assert_response :success
  end
end
