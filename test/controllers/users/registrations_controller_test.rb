require 'test_helper'
require 'cloudflare/cloudflare'

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Create an unknown user ahead of time so the calls below don't create one and throw off all of the assert_difference counts
    create(:unknown, ip_address: '127.0.0.1')
  end

  test 'new' do
    get new_user_registration_path
    assert_response :success
  end

  test 'create, known with username' do
    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count') do
      post user_registration_path, params: {user: {name: user_attributes[:name], email: user_attributes[:email], password: 'correct', password_confirmation: 'correct'}}
      assert_redirected_to root_path
    end

    user = Users::Known.last

    assert_equal user_attributes[:name], user.name, 'Incorrect name for new user'
    assert_equal user_attributes[:email], user.email, 'Incorrect email for new user'
    assert user.is_a?(Users::Known), 'Incorrect type for new user'
    assert_not_nil user.confirmation_token, 'Confirmation token not set for new user'
  end

  test 'create, known without username' do
    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count') do
      post user_registration_path, params: {user: {email: user_attributes[:email], password: 'correct', password_confirmation: 'correct'}}
      assert_redirected_to root_path
    end

    assert_nil Users::Known.last.name, 'Incorrect name for new user'
  end

  test 'create, known, failed' do
    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count', 0) do
      post user_registration_path, params: {user: {email: user_attributes[:email], password: 'horse', password_confirmation: 'different'}}
      assert_response :success
    end
  end

  test 'create, passing turnstile' do
    Rails.application.credentials.turnstile_secret_key = Cloudflare::TURNSTILE_PASSING

    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count') do
      post user_registration_path, params: {user: {email: user_attributes[:email], password: 'battery', password_confirmation: 'battery'}, 'cf-turnstile-response' => 'foo'}
      assert_redirected_to root_path
    end
  ensure
    Rails.application.credentials.turnstile_secret_key = nil
  end

  test 'create, failing turnstile' do
    Rails.application.credentials.turnstile_secret_key = Cloudflare::TURNSTILE_FAILING

    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count', 0) do
      post user_registration_path, params: {user: {email: user_attributes[:email], password: 'battery', password_confirmation: 'battery'}, 'cf-turnstile-response' => 'foo'}
      assert_response :success
    end
  ensure
    Rails.application.credentials.turnstile_secret_key = nil
  end

  # Admins should not be able to be created by explicitly specifying a user type
  test 'create, admin' do
    assert_difference('Users::User.count') do
      post user_registration_path, params: {user: {email: 'bob@example.com', password: 'staple', password_confirmation: 'staple', type: 'Users::Admin'}}
      assert_redirected_to root_path
      assert Users::User.order(:created_at).last.is_a?(Users::Known), 'Admin created through registation form'
    end
  end

  test 'create, xhr' do
    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count') do
      post user_registration_path, xhr: true, params: {user: {email: user_attributes[:email], password: 'battery', password_confirmation: 'battery'}}
      assert_response :success
    end
  end

  test 'create, xhr, failed' do
    user_attributes = attributes_for(:known)

    assert_difference('Users::User.count', 0) do
      post user_registration_path, xhr: true, params: {user: {email: user_attributes[:email], password: 'battery', password_confirmation: 'different'}}
      assert_response :success
    end
  end

  test 'show' do
    user = create(:known)
    sign_in(user)

    get user_path
    assert_response :success
  end

  test 'activity' do
    user = create(:known)
    create(:action, user: user)
    sign_in(user)

    get activity_user_path
    assert_response :success
  end

  test 'edit' do
    user = create(:known)
    sign_in(user)

    get edit_user_registration_path
    assert_response :success
  end

  test 'update' do
    user = create(:known)
    sign_in(user)

    new_name = 'Bob Hoover'
    patch user_registration_path, params: {user: {name: new_name}}

    assert_redirected_to user_path
    assert_equal new_name, user.reload.name, 'User name not updated'
  end

  test 'destroy' do
    user = create(:known)
    sign_in(user)

    assert_difference('Users::User.count', -1) do
      delete user_registration_path
    end
  end

  test 'update_timezone' do
    user = create(:known)
    sign_in(user)
    timezone = 'America/Denver'

    patch update_timezone_user_path, params: {timezone: timezone}
    assert_response :success

    assert_equal timezone, user.reload.timezone
  end
end
