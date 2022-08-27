require 'test_helper'

class Users::UnlocksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # None of the these routes should be accessible. Unlocks are done by resetting the password
  test 'new' do
    get new_user_unlock_path
    assert_response :forbidden
  end

  test 'create' do
    post user_unlock_path, params: {user: {email: 'alice@example.com'}}
    assert_response :forbidden
  end

  test 'show' do
    get user_unlock_path, params: {user: {unlock_token: 'token'}}
    assert_response :forbidden
  end
end
