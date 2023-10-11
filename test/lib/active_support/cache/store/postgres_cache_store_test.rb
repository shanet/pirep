require 'test_helper'
require 'active_support/cache/store/postgres_cache_store'

class PostgresCacheStoreTest < ActiveSupport::TestCase
  setup do
    @cache = ActiveSupport::Cache::PostgresCacheStore.new
    @key = 'foo'
  end

  test 'reads/writes value' do
    @cache.write(@key, 'bar')
    assert_equal 'bar', @cache.read(@key), 'Did not read expected value from cache'
  end

  test 'reading expired key deletes it' do
    # Reading an expired key should return nil and remove it from the cache
    @cache.write(@key, 'expired', expires_at: 1.minute.from_now)

    travel_to(1.hour.from_now) do
      assert_difference('@cache.size', -1) do
        assert_nil @cache.read(@key), 'Did not return nil from expired key'
      end
    end
  end

  test 'increment non-existant key' do
    # Incremeneting a non-existant key should keep the value at zero as there's nothing to increment
    @cache.increment(@key)
    assert_nil @cache.read(@key), 'Incremented non-existant key'
  end

  test 'increment key' do
    @cache.write(@key, 0)
    @cache.increment(@key)
    assert_equal 1, @cache.read(@key), 'Did not read increment value'

    @cache.increment(@key, 10)
    assert_equal 11, @cache.read(@key), 'Did not read increment value'
  end

  test 'decrement non-existant key' do
    @cache.decrement(@key)
    assert_nil @cache.read(@key), 'Decremented non-existant key'
  end

  test 'decrement key' do
    @cache.write(@key, 0)
    @cache.decrement(@key)
    assert_equal(-1, @cache.read(@key), 'Did not read decrement value')

    @cache.decrement(@key, 10)
    assert_equal(-11, @cache.read(@key), 'Did not read decrement value')
  end

  test 'clear cache' do
    @cache.write(@key, 42)
    assert_equal 42, @cache.read(@key), 'Did not read expected value from cache'

    @cache.clear
    assert_nil @cache.read(@key), 'Did not clear cache'
  end

  test 'cleanup cache' do
    @cache.write("#{@key}-no-expiration", 'no expiration')
    @cache.write("#{@key}-expired", 'expired', expires_at: 1.minute.from_now)
    @cache.write("#{@key}-not-expired", 'not expired', expires_in: 1.hour)

    # Cleaning up the cache should only remove the expired key
    travel_to(10.minutes.from_now) do
      assert_difference('@cache.size', -1) do
        @cache.cleanup
      end
    end
  end
end
