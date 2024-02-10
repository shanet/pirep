require 'exceptions'
require_relative 'cloudflare_stubs'

module Cloudflare
  # https://developers.cloudflare.com/turnstile/reference/testing/
  TURNSTILE_PASSING = '1x0000000000000000000000000000000AA'
  TURNSTILE_FAILING = '2x0000000000000000000000000000000AA'

  def self.client
    if (Rails.application.credentials.turnstile_secret_key.blank? && !Rails.env.production?) || Rails.env.test?
      CloudflareStubs.stub_requests
    end

    return Service.new
  end

  class Service
    def valid_turnstile_response?(candidate)
      payload = {secret: Rails.application.credentials.turnstile_secret_key, response: candidate}
      response = Faraday.post('https://challenges.cloudflare.com/turnstile/v0/siteverify', payload)
      return false unless response.success?

      return JSON.parse(response.body)['success']
    end
  end
end
