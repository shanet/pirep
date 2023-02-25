ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'
require 'active_support/testing/method_call_assertions'

Aws.config[:stub_responses] = true

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::MethodCallAssertions
  include FactoryBot::Syntax::Methods

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_request = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true

    yield
  ensure
    PaperTrail.enabled = was_enabled
    PaperTrail.request.enabled = was_enabled_for_request
  end

  def with_rack_attack
    was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = true
    yield
  ensure
    Rack::Attack.enabled = was_enabled
  end

  def with_airports_cache
    was_enabled = AirportGeojsonDumper.enabled
    AirportGeojsonDumper.enabled = true
    yield
  ensure
    AirportGeojsonDumper.enabled = was_enabled
    AirportGeojsonDumper.new.clear_cache!
  end
end

# Include Devise helpers for signing in/out users
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in(user)
    super (user.is_a?(Users::User) ? user : create(user)) # rubocop:disable Rails/SaveBang
  end
end

class ActionDispatch::SystemTestCase
  def sign_in(user, controller: :map)
    user = (user.is_a?(Users::User) ? user : create(user)) # rubocop:disable Rails/SaveBang

    case controller
      when :map
        visit root_path
        click_link 'Log In'
      when :sessions
        visit new_user_session_path
      else
        flunk 'Unknown sign-in controller type'
    end

    fill_in 'login-email', with: user.email
    fill_in 'login-password', with: user.password
    click_button 'Log in'

    # If an admin check that we're on the manage dashboard
    if user.is_a? Users::Admin
      assert_selector '.navbar', text: 'Logout'
    else
      assert_selector '.map-header', text: 'Logout', wait: (ENV['CI'] ? 300 : 30)
    end
  end
end
