require 'application_system_test_case'

class TimezoneTest < ApplicationSystemTestCase
  test 'sets user timezone if not set' do
    user = create(:known)
    sign_in user

    visit root_path
    browser_timezone = page.evaluate_script('Intl.DateTimeFormat().resolvedOptions().timeZone')

    assert_equal browser_timezone, user.reload.timezone, 'User timezone not set to browser timezone'
  end

  test 'does not set user timezone if set' do
    user = create(:known, timezone: Rails.configuration.default_timezone)
    sign_in user

    visit root_path
    assert_equal Rails.configuration.default_timezone, user.reload.timezone, 'User timezone overwritten'
  end
end
