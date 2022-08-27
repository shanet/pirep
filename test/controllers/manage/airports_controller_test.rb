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
    assert_response :redirect
  end
end
