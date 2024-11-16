require 'policy_test'

class ActionPolicyTest < PolicyTest
  test 'scope' do
    assert_scope([:admin, :known, :unknown], [], [create(:action)], Action)
  end
end
