require 'policy_test'

class CommentPolicyTest < PolicyTest
  ['create', 'helpful', 'flag_outdated', 'undo_outdated'].each do |action|
    test action do
      assert_allows_all :comment, action, allow_disabled: false
    end
  end

  test 'destroy' do
    assert_allows_admin(create(:comment), :destroy)
  end
end
