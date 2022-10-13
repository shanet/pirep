require 'test_helper'

class AirportBoundingBoxCalculatorTest < ActiveSupport::TestCase
  setup do
    @airport = create(:airport)

    @expected_bounding_box = {
      southwest: {
        latitude: 48.8382765,
        longitude: -117.2840137,
      },
      northeast: {
        latitude: 48.8436501,
        longitude: -117.2839675,
      },
    }
  end

  test 'calculates bounding box for airport' do
    bounding_box = AirportBoundingBoxCalculator.new.calculate(@airport)
    assert_equal @expected_bounding_box, bounding_box, 'Incorrect bounding box for airport'
  end
end
