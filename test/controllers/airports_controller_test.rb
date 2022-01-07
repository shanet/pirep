require 'test_helper'

class AirportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport)
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

  test 'updates airport' do
    patch airport_path(@airport), params: {airport: {description: 'description'}}
    assert_response :redirect
  end

  test 'searches airports' do
    get search_airports_path(query: @airport.code)

    assert_response :success
    assert_equal @airport.code, JSON.parse(response.body).first['code'], 'Airport not returned from search'
  end
end
