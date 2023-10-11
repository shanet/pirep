require 'policy_test'

class VersionPolicyTest < PolicyTest
  test 'revert' do
    assert_allows_admin create(:airport), :revert
  end
end
