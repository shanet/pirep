require 'test_helper'

class AirportCompletionProgressCalculatorTest < ActiveSupport::TestCase
  test 'progress for empty airport' do
    assert_equal 0, AirportCompletionProgressCalculator.new(create(:airport, :empty)).percent_complete, 'Unexpected completion percent for empty airport'
  end

  test 'progress for airport' do
    assert_equal 90, AirportCompletionProgressCalculator.new(create(:airport)).percent_complete, 'Unexpect completion percent for airport'
  end

  test 'missing information for airport' do
    airport = create(:airport, :empty, description: 'lorem ipsum')
    missing_information = AirportCompletionProgressCalculator.new(airport).missing_information

    assert_nil missing_information[:description], 'Description present but marked as missing'
    assert_nil missing_information[:landing_rights], 'Landing rights present but should never appear'
    assert_equal 10, missing_information.count, 'Unexpected amount of missing information items'
  end

  test 'featured airport?' do
    assert AirportCompletionProgressCalculator.new(create(:airport, :featured)).featured?, 'Featured airport not marked as featured'
    assert_not AirportCompletionProgressCalculator.new(create(:airport)).featured?, 'Empty airport marked as featured'
  end
end
