require 'policy_test'

module Manage
  class CommentPolicyTest < PolicyTest
    ['index', 'show', 'edit', 'update', 'destroy'].each do |action|
      test action do
        assert_allows_admin :manage_comment, action
      end
    end

    test 'scope' do
      assert_scope([:admin], [:known, :unknown], [create(:comment)], Comment)
    end
  end
end
