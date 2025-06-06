require 'test_helper'

class AirportCompletionProgressCalculatorTest < ActiveSupport::TestCase
  test 'progress for empty airport' do
    assert_equal 0, AirportCompletionProgressCalculator.new(create(:airport, :empty)).percent_complete, 'Unexpected completion percent for empty airport'
  end

  test 'progress for airport' do
    assert_equal 90, AirportCompletionProgressCalculator.new(create(:airport)).percent_complete, 'Unexpected completion percent for airport'
  end

  test 'progress for airport with multiple items' do
    airport = create(:airport, :empty)

    # Certain items added to an airport should count multiple times
    [:golfing, :museum].each do |tag_name|
      airport.tags << create(:tag, name: tag_name)
    end

    3.times {airport.webcams << create(:webcam)}
    3.times {airport.contributed_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))}
    airport.update!(annotations: (0..2).map {{label: '1', latitude: 0, longitude: 0}})

    assert_equal 95, AirportCompletionProgressCalculator.new(airport).percent_complete, 'Unexpected completion percent for airport'
  end

  test 'progress for airport is capped at 100%' do
    airport = create(:airport, annotations: (0..100).map {{label: '1', latitude: 0, longitude: 0}})
    assert_equal AirportCompletionProgressCalculator::FEATURED_THRESHOLD, AirportCompletionProgressCalculator.new(airport).percent_complete, 'Unexpected completion percent for airport'
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
