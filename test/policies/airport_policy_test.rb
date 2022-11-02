require 'policy_test'

class AirportPolicyTest < PolicyTest
  ['index', 'show', 'search', 'history', 'preview'].each do |action|
    test action do
      assert_allows_all :airport, action
    end
  end

  ['new', 'create', 'update'].each do |action|
    test action do
      assert_allows_all :airport, action, allow_disabled: false
    end
  end

  test 'revert' do
    assert_allows_admin :airport, :revert
  end
end
