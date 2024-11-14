require 'application_system_test_case'

class SessionsTest < ApplicationSystemTestCase
  # Test both admin and known users
  [:known, :admin].each do |user|
    test "logs in and logs out #{user} via map controller" do
      sign_in user

      click_link_or_button 'Logout'
      find_by_id('hamburger-icon').click
      assert_selector '#hamburger-menu', text: 'Log In / Register'
    end
  end

  test 'handle log in failure via map controller' do
    visit root_path
    find_by_id('hamburger-icon').click
    click_link_or_button 'Log In / Register'

    fill_in 'user_email', with: 'fake@example.com'
    fill_in 'user_password', with: 'hunter2'
    click_link_or_button 'Log in'

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

    fill_in 'user_email', with: 'fake@example.com'
    fill_in 'user_password', with: 'hunter2'
    click_link_or_button 'Log in'

    # An error message should be shown
    assert_selector '.alert', text: 'Invalid Email or password.'
  end
end
