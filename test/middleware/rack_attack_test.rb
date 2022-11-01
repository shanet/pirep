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
    # TODO
  end

  test 'throttles airport updates' do
    with_rack_attack do
      assert_throttles airport_path(create(:airport)), :patch, Rails.configuration.rack_attack_write_limit,
                       expected_response: :redirect, **{airport: {description: ''}}
    end
  end

  test 'throttles comment creates' do
    with_rack_attack do
      assert_throttles comments_path, :post, Rails.configuration.rack_attack_write_limit,
                       expected_response: :redirect, **{comment: {body: 'a', airport_id: create(:airport).id}}
    end
  end

  test 'throttles login attempts' do
    with_rack_attack do
      assert_throttles user_session_path, :post, Rails.configuration.rack_attack_write_limit
    end
  end

  test 'throttles account registrations' do
    with_rack_attack do
      assert_throttles user_registration_path, :post, Rails.configuration.rack_attack_write_limit, **{user: {email: 'alice@example.com'}}
    end
  end

private

  def assert_throttles(path, method, num_requests, expected_response: :success, **params)
    num_requests.times do
      send(method, path, params: params)
      assert_response expected_response
    end

    # One more request should put us over the limit
    send(method, path, params: params)
    assert_response TOO_MANY_REQUESTS
  end
end
