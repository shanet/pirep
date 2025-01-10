require 'application_system_test_case'

class LeaderboardTest < ApplicationSystemTestCase
  setup do
    @users = (LeaderboardController::LEADERBOARD_LENGTH + 1).times.map do |index|
      create(:known, points: index)
    end
  end

  test 'has leaderboard in correct order' do
    visit leaderboard_path

    nodes = all('table td:nth-child(2)')
    assert_equal LeaderboardController::LEADERBOARD_LENGTH, nodes.count, 'Unexpected leaderboard length'

    # The order of the leaderboard should be from highest to lowest so reverse users list and only consider the first N users
    @users.reverse[0...LeaderboardController::LEADERBOARD_LENGTH].each_with_index do |user, index|
      assert_equal user.name, nodes[index].text, "Wrong leaderboard order for #{user.name} (#{index})"
    end
  end
end
