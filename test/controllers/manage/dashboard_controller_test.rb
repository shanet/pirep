require 'test_helper'

class Manage::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :admin
  end

  test 'dashboard' do
    get manage_root_path
    assert_response :success
  end

  test 'activity' do
    # Create an action to be rendered as a basic sanity check for this page
    create(:action)

    get manage_activity_path
    assert_response :success
  end
end
