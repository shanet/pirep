require 'policy_test'

module Users
  class SessionsPolicyTest < PolicyTest
    ['new', 'create'].each do |action|
      test action do
        assert_allows_all :session, action
      end
    end

    test 'destroy' do
      assert_allows_users :session, :destroy
    end
  end
end
