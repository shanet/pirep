require 'policy_test'

module Users
  class RegistrationsPolicyTest < PolicyTest
    setup do
      @user1 = create(:known)
      @user2 = create(:known)
    end

    test 'new' do
      assert_allows_all :registration, :new, allow_disabled: false
    end

    test 'create' do
      assert_allows_all :registration, :create, allow_disabled: false

      Rails.configuration.read_only.enable!
      assert_denies_all :registration, :create
    ensure
      Rails.configuration.read_only.disable!
    end

    ['show', 'activity', 'edit', 'update', 'destroy', 'update_timezone'].each do |action|
      test action do
        assert_allows @user1, @user1, action, 'Denied user editing self'
        assert_denies @user2, @user1, action, 'Allowed user to edit other user'
      end
    end
  end
end
