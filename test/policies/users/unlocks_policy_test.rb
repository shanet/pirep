require 'policy_test'

module Users
  class UnlocksPolicyTest < PolicyTest
    ['new', 'create', 'show'].each do |action|
      test action do
        assert_denies_all :unlock, action
      end
    end
  end
end
