require 'policy_test'

class EventPolicyTest < PolicyTest
  setup do
    @event = create(:event)
  end

  ['create', 'edit', 'update', 'destroy'].each do |action|
    test action do
      assert_allows_all @event, action, allow_disabled: false
    end
  end

  test 'show' do
    assert_allows_all @event, :show
  end

  test 'revert' do
    assert_allows_admin @event, :revert
  end
end
