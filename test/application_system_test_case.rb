require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = (ENV['HEADLESS'] == 'false' ? :chrome : :headless_chrome)

  driven_by :selenium, using: driver, screen_size: [1400, 1400] do |options|
    # Enable WebGL for Mapbox
    options.add_argument('--use-gl')

    # Specifying prefers-reduced-motion tells Mapbox to disable fly-to animations which is useful for tests because it eliminates
    # the need for sleep statements to wait for these animations to complete since it's all done within a canvas element.
    options.add_argument('--force-prefers-reduced-motion')

    # Support Wayland if being used (`auto` should detect it, well, automatically, but this seems to cause CI failures)
    options.add_argument('--ozone-platform-hint=auto') if ENV['XDG_SESSION_TYPE'] == 'wayland'
  end

  # CI on GitHub actions runs wayyyyyyy slower due to lack of GPU acceleration and Mapbox needing WebGL so give it more time before failing a test
  Capybara.default_max_wait_time = 300 if ENV['CI']

  # We'll get far fewer flakes without animations
  Capybara.disable_animation = true

  # Silence some annoying "Capybara starting Puma..." while running tests
  Capybara.server = :puma, {Silent: true}

  def wait_for_map_ready(id='map')
    # Once the map is fully ready to use it will populate a data attribute
    # Mapbox runs incredibly slow on CI so give it a bunch of time before failing
    find("##{id}[data-ready=\"true\"]", wait: (ENV['CI'] ? 300 : 60))
  rescue Capybara::ElementNotFound => error
    # Something may have prevented Mapbox from initalizing, it would he helpful to print the browser logs in this case
    warn page.driver.browser.logs.get(:browser)
    raise error
  end
end
