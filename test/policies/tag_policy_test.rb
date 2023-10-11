require 'policy_test'

class TagPolicyTest < PolicyTest
  setup do
    @tag = create(:tag)
  end

  test 'destroy' do
    assert_allows_all @tag, :destroy, allow_disabled: false
  end

  test 'revert' do
    assert_allows_admin @tag, :revert
  end
end
