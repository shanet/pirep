require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = (ENV['HEADLESS'] == 'false' ? :chrome : :headless_chrome)

  driven_by :selenium, using: driver, screen_size: [1400, 1400] do |options|
    # Enable WebGL for Mapbox
    options.add_argument('--use-gl')
  end

  # CI runs somewhat slower so give it some more time before failing a test
  Capybara.default_max_wait_time = 10 if ENV['CI']
  Capybara.disable_animation = true
end
