require 'policy_test'

module Manage
  class WebcamPolicyTest < PolicyTest
    test 'destroy' do
      assert_allows_admin :webcam, :destroy
    end
  end
end
