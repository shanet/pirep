require 'policy_test'

module Users
  class RegistrationsPolicyTest < PolicyTest
    setup do
      @user1 = create(:known)
      @user2 = create(:known)
    end

    ['new', 'create'].each do |action|
      test action do
        assert_allows_all :registration, action, allow_disabled: false
      end
    end

    ['show', 'activity', 'edit', 'update', 'destroy', 'update_timezone'].each do |action|
      test action do
        assert_allows @user1, @user1, action, 'Denied user editing self'
        assert_denies @user2, @user1, action, 'Allowed user to edit other user'
      end
    end
  end
end
