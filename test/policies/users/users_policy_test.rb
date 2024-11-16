require 'policy_test'

module Users
  class UsersPolicyTest < PolicyTest
    setup do
      @user = create(:known)
    end

    ['show', 'activity'].each do |action|
      test action do
        assert_allows_all @user, action
      end
    end
  end
end
