require 'test_helper'
require 'open_street_maps/open_street_maps_api'

class OpenStreetMapsApiTest < ActiveSupport::TestCase
  setup do
    @client = OpenStreetMapsApi.client
  end

  test 'finds bounding box of airport' do
    bounding_box = @client.bounding_box(42.123, -122.0)
    assert_equal 3, bounding_box[:elements].count, 'Bounding box not found'
  end
end
