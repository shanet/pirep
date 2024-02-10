require 'test_helper'
require 'cloudflare/cloudflare'

class CloudflareTest < ActiveSupport::TestCase
  setup do
    @client = Cloudflare.client
  end

  test 'accepts turnstile response' do
    Rails.application.credentials.turnstile_secret_key = Cloudflare::TURNSTILE_PASSING
    assert @client.valid_turnstile_response?('foobar'), 'Turnstile response not valid with passing test key'
  ensure
    Rails.application.credentials.turnstile_secret_key = nil
  end

  test 'rejects turnstile response' do
    Rails.application.credentials.turnstile_secret_key = Cloudflare::TURNSTILE_FAILING
    assert_not @client.valid_turnstile_response?('foobar'), 'Turnstile response valid with failing test key'
  ensure
    Rails.application.credentials.turnstile_secret_key = nil
  end
end
