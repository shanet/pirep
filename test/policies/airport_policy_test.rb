require 'policy_test'

class AirportPolicyTest < PolicyTest
  ['index', 'show', 'update', 'search', 'history', 'preview'].each do |action|
    test action do
      assert_allows_all :airport, action
    end
  end

  test 'revert' do
    assert_allows_admin :airport, :revert
  end
end
