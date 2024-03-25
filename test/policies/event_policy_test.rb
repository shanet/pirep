require 'policy_test'

class EventPolicyTest < PolicyTest
  setup do
    @event = create(:event)
  end

  ['create', 'update', 'destroy'].each do |action|
    test action do
      assert_allows_all @event, action, allow_disabled: false, allow_unverified: false
    end
  end

  ['show', 'edit'].each do |action|
    test action do
      assert_allows_all @event, action
    end
  end

  test 'revert' do
    assert_allows_admin @event, :revert
  end
end
