require 'policy_test'

class TagPolicyTest < PolicyTest
  test 'destroy' do
    assert_allows_all :tag, :destroy
  end
end
