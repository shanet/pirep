require 'test_helper'

class Manage::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:known)
    sign_in :admin
  end

  test 'index' do
    get manage_users_path
    assert_response :success
  end

  test 'show' do
    get manage_user_path(@user)
    assert_response :success
  end

  test 'edit' do
    get edit_manage_user_path(@user)
    assert_response :success
  end

  test 'update' do
    patch manage_user_path(@user, params: {users_user: {name: 'foo'}})
    assert_response :redirect
  end
end
