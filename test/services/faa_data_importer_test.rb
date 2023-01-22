require 'test_helper'

class FaaDataImporterTest < ActiveSupport::TestCase
  test 'imports FAA data' do
    assert_difference('Airport.count', 1) do
      FaaDataImporter.new(force_update: true).import!
    end

    # Check that the current data cycle was written to the cache
    [:airports, :diagrams, :charts].each do |product|
      assert_equal FaaApi.client.current_data_cycle(product).iso8601, Rails.configuration.faa_data_cycle.current(product, stub: false), 'FAA data cycle not updated on airport import'
    end
  end

  test 'skips current data cycle' do
    # TODO
  end
end
