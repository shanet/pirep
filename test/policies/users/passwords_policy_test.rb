require 'policy_test'

module Users
  class PasswordsPolicyTest < PolicyTest
    ['new', 'create', 'edit', 'update'].each do |action|
      test action do
        assert_allows_all :password, action
      end
    end
  end
end
