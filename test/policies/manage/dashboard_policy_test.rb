require 'policy_test'

module Manage
  class DashboardPolicyTest < PolicyTest
    ['index', 'activity', 'update_read_only'].each do |action|
      test action do
        assert_allows_admin :manage_dashboard, action
      end
    end
  end
end
