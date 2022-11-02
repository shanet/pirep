require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = (ENV['HEADLESS'] == 'false' ? :chrome : :headless_chrome)

  driven_by :selenium, using: driver, screen_size: [1400, 1400] do |options|
    # Enable WebGL for Mapbox
    options.add_argument('--use-gl')

    # Specifying prefers-reduced-motion tells Mapbox to disable fly-to animations which is useful for
    # tests because it eliminates the need for sleep statements to wait for these animations to complete
    options.add_argument('--force-prefers-reduced-motion')
  end

  # CI runs somewhat slower so give it some more time before failing a test
  Capybara.default_max_wait_time = 10 if ENV['CI']

  # We'll get far fewer flakes without animations
  Capybara.disable_animation = true

  # Silence some annoying "Capybara starting Puma..." while running tests
  Capybara.server = :puma, {Silent: true}
end
