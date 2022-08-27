require 'test_helper'

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @password = 'fishsticks'
    @known = create :known, password: @password
    @admin = create :admin, password: @password
  end

  test 'new' do
    get new_user_session_path
    assert_response :success
  end

  test 'create, known user' do
    post user_session_path, params: {user: {email: @known.email, password: @password}}
    assert_redirected_to root_path
  end

  test 'create, admin user' do
    post user_session_path, params: {user: {email: @admin.email, password: @password}}
    assert_redirected_to manage_root_path
  end

  test 'create, failed login' do
    post user_session_path, params: {user: {email: @admin.email, password: 'wrong'}}
    assert_response :success
  end

  test 'create, known user, xhr' do
    post user_session_path, xhr: true, params: {user: {email: @known.email, password: @password}}
    assert_response :success
  end

  test 'create, failed login, xhr' do
    post user_session_path, xhr: true, params: {user: {email: @admin.email, password: 'wrong'}}
    assert_response :unauthorized
  end

  test 'destroy' do
    sign_in @admin

    delete destroy_user_session_path
    assert_redirected_to root_path

    # Confirm we are signed out now
    get manage_root_path
    assert_response :forbidden
  end
end
