require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = (ENV['HEADLESS'] == 'false' ? :chrome : :headless_chrome)

  driven_by :selenium, using: driver, screen_size: [1400, 1400] do |options|
    # We need to enable WebGL for Mapbox
    options.add_argument('--use-gl')
  end

  Capybara.disable_animation = true
end
