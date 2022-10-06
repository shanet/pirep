require 'policy_test'

class ActionPolicyTest < PolicyTest
  test 'scope' do
    # Users should be able to access their own actions
    known = create(:known)
    action = create(:action, user: known)

    assert_scope([:admin, known], [:known, :unknown], [action], Action)
  end
end
