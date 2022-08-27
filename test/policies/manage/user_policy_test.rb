require 'policy_test'

module Manage
  class UserPolicyTest < PolicyTest
    ['index', 'show', 'edit', 'update', 'destroy'].each do |action|
      test action do
        assert_allows_admin :manage_user, action
      end
    end
  end
end
