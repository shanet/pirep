require 'test_helper'
require 'google/google_api'

class GoogleApiTest < ActiveSupport::TestCase
  setup do
    @client = GoogleApi.client
  end

  test 'retrieves photos' do
    photos = @client.place_photos('Blerg Airport', 42.123, -122.0)

    assert_equal 2, photos.length, 'Wrong number of photos returned'
    assert photos.first[:url].present?, 'Image URL not returned'
    assert photos.first[:attribution].present?, 'Image attribution not returned'
  end

  test 'combines multiple attributions with CSV' do
    photos = @client.place_photos('Blerg Airport', 42.123, -122.0)

    assert photos.first[:attribution].present?, 'Attribution should be present'
    assert_equal 'Google Place Photos API key not set, using fallback image', photos.first[:attribution]
  end

  test 'retrieves timezone' do
    airport = create(:airport)
    timezone = @client.timezone(airport.latitude, airport.longitude)
    assert_equal 'America/Los_Angeles', timezone, 'Wrong timezone returned'
  end
end
