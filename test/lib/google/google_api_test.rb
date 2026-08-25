require 'test_helper'
require 'google/google_api'

class GoogleApiTest < ActiveSupport::TestCase
  setup do
    @client = GoogleApi.client
  end

  test 'retrieves photos' do
    place_photos = @client.place_photos('Blerg Airport', 42.123, -122.0)

    assert place_photos[:place_id].present?, 'Place ID not returned'
    assert_equal 2, place_photos[:photos].length, 'Wrong number of photos returned'

    assert place_photos[:photos].first[:url].present?, 'Image URL not returned'
    assert place_photos[:photos].first[:attribution].present?, 'Image attribution not returned'
    assert place_photos[:photos].first[:google_photo_reference].present?, 'Google photo reference not returned'
  end

  test 'combines multiple attributions with CSV and sanitizes HTML' do
    photos = @client.place_photos('Blerg Airport', 42.123, -122.0)[:photos]

    assert photos.first[:attribution].present?, 'Attribution should be present'
    assert_equal 'Google Place Photos API key not set, using fallback image', photos.first[:attribution]

    # The second photo stub should have sanitized HTML
    assert_equal '<a href="https://example.com">Google Place Photos API key not set, using fallback image</a>alert("xss")', photos.last[:attribution]
    assert_not_includes photos.last[:attribution], '<script>', 'Script tags should be stripped'
  end

  test 'retrieves timezone' do
    airport = create(:airport)
    timezone = @client.timezone(airport.latitude, airport.longitude)
    assert_equal 'America/Los_Angeles', timezone, 'Wrong timezone returned'
  end
end
