require 'test_helper'

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    get leaderboard_path
    assert_response :success
  end
end
