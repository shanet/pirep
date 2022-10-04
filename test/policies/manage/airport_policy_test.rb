require 'policy_test'

module Manage
  class AirportPolicyTest < PolicyTest
    ['index', 'search', 'show', 'edit', 'update', 'update_version'].each do |action|
      test action do
        assert_allows_admin :manage_airport, action
      end
    end
  end
end
