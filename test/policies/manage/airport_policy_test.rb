require 'policy_test'

module Manage
  class AirportPolicyTest < PolicyTest
    ['index', 'search', 'show', 'edit', 'update', 'destroy', 'destroy_attachment', 'analytics', 'update_version'].each do |action|
      test action do
        assert_allows_admin :manage_airport, action
      end
    end

    test 'scope' do
      assert_scope([:admin], [:known, :unknown], [create(:airport)], Airport)
    end
  end
end
