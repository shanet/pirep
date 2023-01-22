require 'test_helper'

class FaaDataCycleTest < ActiveSupport::TestCase
  setup do
    # Since the ReadOnly instance on the Rails.configuration is a lazy loading object we need to
    # directly call the instance here at least once so it will create the database record if
    # necessary. Otherwise, not having the database record created will result in inconsistent
    # test failures on the test below which checks if calling this method does not create
    # a new database record depending on the test run order.
    FaaDataCycle.instance

    @product = :charts
  end

  teardown do
    # Ensure that we always have read only mode disabled regardless of what a test does here
    Rails.configuration.faa_data_cycle.clear!
  end

  test 'getting instance does not create a new record' do
    assert_difference('FaaDataCycle.count', 0) do
      FaaDataCycle::Loader.new.current(@product)
      FaaDataCycle.instance
    end
  end

  test 'cannot call new method of singleton' do
    assert_raises(NoMethodError) do
      FaaDataCycle.new
    end
  end

  test 'has data cycle' do
    assert_equal FaaApi.client.current_data_cycle(@product).iso8601, Rails.configuration.faa_data_cycle.current(@product, stub: false), 'Unexpected data cycle'
  end

  test 'stubs data cycle' do
    assert_equal 'current', Rails.configuration.faa_data_cycle.current(@product), 'Unexpected data cycle with stub'
  end

  test 'next data cycle' do
    Rails.configuration.faa_data_cycle.update_data_cycles

    # Modify the cache to have an old data cycle in it to ensure requesting the next one will return a newer date
    Rails.configuration.faa_data_cycle[@product] = '1970-01-01'
    Rails.configuration.faa_data_cycle.save!

    assert_not_equal FaaApi.client.current_data_cycle(@product).iso8601, Rails.configuration.faa_data_cycle.current(@product, stub: false), 'Unexpected current data cycle'
    assert_equal FaaApi.client.current_data_cycle(@product).iso8601, Rails.configuration.faa_data_cycle.next(@product, stub: false), 'Unexpected next data cycle'
  end

  test 'clears cached data cycle' do
    Rails.configuration.faa_data_cycle.update_data_cycles
    assert Rails.configuration.faa_data_cycle.send(@product).present?, 'Data cycle not written'

    Rails.configuration.faa_data_cycle.clear!
    assert Rails.configuration.faa_data_cycle.send(@product).blank?, 'Data cycle not cleared'
  end
end
