require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = (ENV['HEADLESS'] == 'false' ? :chrome : :headless_chrome)

  driven_by :selenium, using: driver, screen_size: [1400, 1400] do |options|
    # Enable WebGL for Mapbox
    options.add_argument('--use-gl')

    # Specifying prefers-reduced-motion tells Mapbox to disable fly-to animations which is useful for tests because it eliminates
    # the need for sleep statements to wait for these animations to complete since it's all done within a canvas element.
    options.add_argument('--force-prefers-reduced-motion')

    # Fix a CI issue with Ubuntu 24.04 ("session not created: DevToolsActivePort file doesn't exist")
    options.add_argument('--remote-debugging-pipe')

    # Support Wayland if being used (`auto` should detect it, well, automatically, but this seems to cause CI failures)
    options.add_argument('--ozone-platform-hint=auto') if ENV['XDG_SESSION_TYPE'] == 'wayland'
  end

  # CI on GitHub actions runs wayyyyyyy slower due to lack of GPU acceleration and Mapbox needing WebGL so give it more time before failing a test
  Capybara.default_max_wait_time = 60 if ENV['CI']

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

  def sign_in(user, controller: :map)
    user = (user.is_a?(Users::User) ? user : create(user)) # rubocop:disable Rails/SaveBang

    case controller
      when :map
        visit root_path
        find_by_id('hamburger-icon').click
        click_link_or_button 'Log In / Register'
      when :sessions
        visit new_user_session_path
      else
        flunk 'Unknown sign-in controller type'
    end

    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_link_or_button 'Log in'

    # If an admin check that we're on the manage dashboard
    if user.is_a? Users::Admin
      assert_selector '.navbar', text: 'Logout'
    else
      assert_selector '.navigation', text: 'Account'
      find_by_id('hamburger-icon').click
      assert_selector '#hamburger-menu', text: 'Logout'
    end
  end
end
