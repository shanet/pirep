require 'application_system_test_case'

class RegistrationsTest < ApplicationSystemTestCase
  test 'registers user via map controller' do
    register_user_map_controller
    assert_registration_success
  end

  test 'handle registration failure via map controller' do
    register_user_map_controller passwords_match: false

    # The registration drawer should still be open
    assert_selector '#login-tabs'

    # An error message should be shown
    assert_selector '#registration-form .ajax-errors', text: 'Password confirmation doesn\'t match Password'
  end

  test 'registers user via registrations controller' do
    visit new_user_registration_path
    submit_registration_form
    assert_registration_success
  end

  test 'handle registration failure via registrations controller' do
    visit new_user_registration_path
    submit_registration_form passwords_match: false

    # An error message should be shown
    assert_selector '.alert', text: 'Password confirmation doesn\'t match Password'
  end

private

  def register_user_map_controller(passwords_match: true)
    visit root_path
    find_by_id('hamburger-icon').click
    click_link_or_button 'Log In / Register'
    click_link_or_button 'Register'

    submit_registration_form(passwords_match: passwords_match)
  end

  def submit_registration_form(passwords_match: true)
    fill_in 'registration-email', with: 'new_user@example.com'
    fill_in 'registration-password', with: 'password'
    fill_in 'Password confirmation', with: (passwords_match ? 'password' : 'different')
    click_link_or_button 'Sign up'

    # Wait for the form to submit before continuing
    assert_no_selector '#registration-form input[type="submit"][disabled]'
  end

  def assert_registration_success
    assert_selector '.toast-body', text: 'Welcome! You have signed up successfully.'
    find_by_id('hamburger-icon').click
    assert_selector '#hamburger-menu', text: 'Logout'
  end
end
