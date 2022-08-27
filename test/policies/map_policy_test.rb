require 'policy_test'

class MapPolicyTest < PolicyTest
  test 'index' do
    assert_allows_all :map, :index
  end
end
