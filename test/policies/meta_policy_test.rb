require 'policy_test'

class MetaPolicyTest < PolicyTest
  test 'index' do
    assert_allows_all :meta, :health
  end
end
