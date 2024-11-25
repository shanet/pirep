require 'test_helper'

class Users::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @known = create(:known)
    @unknown = create(:unknown, ip_address: '127.0.0.1')
  end

  test 'show, known user' do
    get users_show_user_path(@known)
    assert_response :success
  end

  test 'show, unknown user' do
    get users_show_user_path(@unknown)
    assert_response :success
  end

  test 'activity, known user' do
    get users_activity_user_path(@known)
    assert_response :success
  end

  test 'activity, unknown user' do
    get users_activity_user_path(@unknown)
    assert_response :success
  end

  test 'redirects to private show page if self' do
    sign_in @known
    get users_show_user_path(@known)
    assert_redirected_to user_path
  end
end
