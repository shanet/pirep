require 'test_helper'

class AirportGeojsonCacherTest < ActiveSupport::TestCase
  test 'writes digest to cache' do
    with_caching do
      digest = AirportGeojsonCacher.update_digest
      assert_equal digest, AirportGeojsonCacher.read_digest, 'GeoJSON cache not set'
    end
  end

  test 'reads digest from cache' do
    with_caching do
      digest = AirportGeojsonCacher.read_digest
      assert_not_nil digest, 'Did not set digest on read when not already set'
      assert_equal digest, AirportGeojsonCacher.read_digest, 'Updated digest on read when already set'
    end
  end

  test 'clears cache' do
    with_caching do
      digest = AirportGeojsonCacher.update_digest
      assert_not_nil digest, 'Did not set digest'
      AirportGeojsonCacher.clear!
      assert_not_equal digest, AirportGeojsonCacher.read_digest, 'Did not clear cache'
    end
  end
end
