require 'application_system_test_case'

class SessionsTest < ApplicationSystemTestCase
  # Test both admin and known users
  [:known, :admin].each do |user|
    test "logs in and logs out #{user} via map controller" do
      sign_in user

      click_on 'Logout'
      assert_selector '.map-header', text: 'Log In'
    end
  end

  test 'handle log in failure via map controller' do
    visit root_path
    click_link 'Log In'

    fill_in 'login-email', with: 'fake@example.com'
    fill_in 'login-password', with: 'hunter2'
    click_button 'Log in'

    # The login drawer should still be open
    assert_selector '#login-tabs'

    # An error message should be shown
    assert_selector '#login-form .ajax-errors', text: 'Invalid Email or password.'
  end

  [:known, :admin].each do |user|
    test "logs in #{user} via sessions controller" do
      sign_in user, controller: :sessions
    end
  end

  test 'handle log in failure via sessions controller' do
    visit new_user_session_path

    fill_in 'login-email', with: 'fake@example.com'
    fill_in 'login-password', with: 'hunter2'
    click_button 'Log in'

    # An error message should be shown
    assert_selector '.alert', text: 'Invalid Email or password.'
  end
end
