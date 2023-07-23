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
end
