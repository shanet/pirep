require 'test_helper'
require 'haversine'

class HaversineTest < ActiveSupport::TestCase
  setup do
    @haversine = Haversine.new
  end

  test 'calculates long distance' do
    assert_in_delta 3865.015, @haversine.distance(47.606101, -122.332931, 40.786595, -73.962109) / 1000, 0.01, 'Incorrect distance Seattle to New York'
  end

  test 'calculates short distance' do
    assert_in_delta 2.09, @haversine.distance(47.908109, -122.281374, 47.924731, -122.268154) / 1000, 0.01, 'Incorrect distance Seattle to New York'
  end

  test 'handles nil arguments' do
    assert_nil @haversine.distance(47.606101, -122.332931, nil, nil), 'Did not handle nil arguments'
  end
end
