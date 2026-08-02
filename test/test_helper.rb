ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'

require 'rails/test_help'
require 'active_support/testing/method_call_assertions'
require 'webmock/minitest'

require_relative Rails.root.join('lib/active_support/cache/store/postgres_cache_store')

Aws.config[:stub_responses] = true
WebMock.disable_net_connect!(allow_localhost: true, allow: 'chromedriver.storage.googleapis.com')

# Ensure we've run any pending GoodJob database migrations
GoodJob.migrated?

Minitest.after_run do
  # Clean up the asset directories (multiple are created with unique names to prevent test threads from stepping on one another)
  ['assets/tiles_test_*', 'assets/airports_cache_test_*'].each do |pattern|
    Rails.public_path.glob(pattern) do |directory|
      FileUtils.rm_rf(directory)
    end
  end
end

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
    cache_store = Rack::Attack.cache.store
    was_enabled = Rack::Attack.enabled
    Rack::Attack.cache.store = ActiveSupport::Cache::PostgresCacheStore.new
    Rack::Attack.enabled = true
    yield
  ensure
    Rack::Attack.enabled = was_enabled
    Rack::Attack.cache.store = cache_store
  end

  def with_airport_geojson_cache
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
    super((user.is_a?(Users::User) ? user : create(user))) # rubocop:disable Rails/SaveBang
  end
end
