require 'policy_test'

module Manage
  class VersionPolicyTest < PolicyTest
    test 'update' do
      assert_allows_admin :manage_version, :update
    end
  end
end
