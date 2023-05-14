require 'test_helper'

class Users::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:known, confirmed_at: nil)
  end

  test 'new' do
    get new_user_confirmation_path
    assert_response :success
  end

  test 'create' do
    post user_confirmation_path, params: {user: {email: @user.email}}

    assert_redirected_to new_user_session_path
    assert_not_nil @user.reload.confirmation_token, 'Confirmation token not set when requested'
  end

  test 'show' do
    # Manually generate a confirmation token for us to use in the request
    raw_token, hashed_token = Devise.token_generator.generate(Users::User, :confirmation_token)
    @user.update!(confirmation_token: hashed_token, confirmation_sent_at: Time.zone.now)

    get user_confirmation_path, params: {confirmation_token: raw_token}

    assert_redirected_to new_user_session_path
    assert_not_nil @user.reload.confirmed_at, 'User not confirmed'
  end
end
