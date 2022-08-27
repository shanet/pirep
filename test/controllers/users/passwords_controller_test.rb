require 'test_helper'

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create :known
  end

  test 'new' do
    get new_user_password_path
    assert_response :success
  end

  test 'create' do
    post user_password_path, params: {user: {email: @user.email}}

    assert_redirected_to new_user_session_path
    assert_not_nil @user.reload.reset_password_token, 'Reset password token not set when requested'
  end

  test 'edit' do
    # It doesn't matter what token we use here as the edit form doesn't validate the token, only the update route does
    get edit_user_password_path, params: {reset_password_token: 'token'}
    assert_response :success
  end

  test 'update' do
    # Manually generate a reset password token for us to use in the request
    raw_token, hashed_token = Devise.token_generator.generate(Users::User, :reset_password_token)
    @user.update!(reset_password_token: hashed_token, reset_password_sent_at: Time.zone.now, locked_at: 1.hour.ago)

    patch user_password_path, params: {user: {password: 'password', password_confirmation: 'password', reset_password_token: raw_token}}
    assert_redirected_to root_path

    # Resetting the password should also unlock the user
    assert_nil @user.reload.locked_at, 'User not unlocked after resetting password'
  end
end
