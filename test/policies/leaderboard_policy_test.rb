require 'policy_test'

class LeaderboardPolicyTest < PolicyTest
  test 'index' do
    assert_allows_all :leaderboard, :index
  end

  test 'scope' do
    assert_scope([:admin, :known, :unknown], [], [create(:known)], Users::User)
  end
end
