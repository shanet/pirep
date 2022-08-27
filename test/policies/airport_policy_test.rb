require 'policy_test'

class AirportPolicyTest < PolicyTest
  ['index', 'show', 'update', 'search'].each do |action|
    test action do
      assert_allows_all :airport, action
    end
  end
end
