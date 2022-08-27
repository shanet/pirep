require 'policy_test'

module Users
  class ConfirmationsPolicyTest < PolicyTest
    ['new', 'create', 'show'].each do |action|
      test action do
        assert_allows_all :confirmation, action
      end
    end
  end
end
