require 'test_helper'

class RackAttackTest < ActionDispatch::IntegrationTest
  TOO_MANY_REQUESTS = 429

  setup do
    Rack::Attack.reset!
  end

  test 'throttles GET requests to root path' do
    with_rack_attack do
      assert_throttles root_path, :get, Rails.configuration.rack_attack_read_limit
    end
  end

  test 'throttles GET requests to airport' do
    with_rack_attack do
      assert_throttles airport_path(create(:airport)), :get, Rails.configuration.rack_attack_read_limit
    end
  end

  test 'throttles airport creates' do
    with_rack_attack do
      assert_throttles airports_path(format: :js), :post, Rails.configuration.rack_attack_write_limit, airport: attributes_for(:airport)
    end
  end

  test 'throttles airport updates' do
    with_rack_attack do
      assert_throttles airport_path(create(:airport)), :patch, Rails.configuration.rack_attack_write_limit,
                       expected_response: :redirect, airport: {description: ''}
    end
  end

  # Routes under /manage should not be throttled
  test 'does not throttles manage airport updates' do
    airport = create(:airport)
    sign_in create(:admin)

    with_rack_attack do
      freeze_time do
        (Rails.configuration.rack_attack_write_limit * 2).times do
          patch manage_airport_path(airport, params: {airport: {reviewed_at: Time.zone.now}})
          assert_response :redirect
        end
      end
    end
  end

  test 'throttles comment creates' do
    with_rack_attack do
      assert_throttles comments_path, :post, Rails.configuration.rack_attack_write_limit,
                       expected_response: :redirect, comment: {body: 'a', airport_id: create(:airport).id}
    end
  end

  test 'throttles login attempts' do
    with_rack_attack do
      assert_throttles user_session_path, :post, Rails.configuration.rack_attack_write_limit
    end
  end

  test 'throttles account registrations' do
    with_rack_attack do
      assert_throttles user_registration_path, :post, Rails.configuration.rack_attack_write_limit, user: {email: 'alice@example.com'}
    end
  end

  test 'clears cache' do
    with_rack_attack do
      assert_equal 0, Rack::Attack.cache.store.size, 'Rack::Attack cache not empty'
      get airport_path(create(:airport))

      travel_to(1.day.from_now) do
        # Make another request. The previous one should be expired and the new one should not. After clearing the cache there should only be one still valid key.
        get airport_path(create(:airport))
        assert_equal 2, Rack::Attack.cache.store.size, 'Rack::Attack cache empty'

        RackAttackCacheCleanerJob.perform_now
        assert_equal 1, Rack::Attack.cache.store.size, 'Rack::Attack cache not empty'
      end
    end
  end

private

  def assert_throttles(path, method, num_requests, expected_response: :success, **params)
    freeze_time do
      num_requests.times do
        send(method, path, params: params)
        assert_response expected_response
      end

      # One more request should put us over the limit
      send(method, path, params: params)
      assert_response TOO_MANY_REQUESTS
    end
  end
end
