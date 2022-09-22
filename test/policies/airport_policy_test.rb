require 'policy_test'

class AirportPolicyTest < PolicyTest
  ['index', 'show', 'search', 'history', 'preview'].each do |action|
    test action do
      assert_allows_all :airport, action
    end
  end

  test 'update' do
    assert_allows_all :airport, :update, allow_disabled: false
  end

  test 'revert' do
    assert_allows_admin :airport, :revert
  end
end
