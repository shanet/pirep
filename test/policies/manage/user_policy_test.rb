require 'policy_test'

module Manage
  class UserPolicyTest < PolicyTest
    ['index', 'search', 'show', 'edit', 'update', 'destroy', 'activity'].each do |action|
      test action do
        assert_allows_admin :manage_user, action
      end
    end
  end
end
