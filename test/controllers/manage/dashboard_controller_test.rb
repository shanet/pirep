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

  test 'update_read_only' do
    patch manage_update_read_only_path, params: {read_only: true}
    assert_redirected_to manage_root_path
    assert Rails.configuration.read_only.enabled?, 'Read only mode not enabled'

    patch manage_update_read_only_path, params: {read_only: false}
    assert_redirected_to manage_root_path
    assert Rails.configuration.read_only.disabled?, 'Read only mode not disabled'
  ensure
    Rails.configuration.read_only.disable!
  end
end
