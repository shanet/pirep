require 'policy_test'

module Manage
  class DashboardPolicyTest < PolicyTest
    test 'index?' do
      assert_allows_admin :manage_dashboard, :index
    end
  end
end
