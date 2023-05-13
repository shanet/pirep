require 'policy_test'

module Manage
  class PageviewPolicyTest < PolicyTest
    test 'scope' do
      assert_scope([:admin], [:known, :unknown], [create(:pageview)], Pageview)
    end
  end
end
