require 'policy_test'

class CommentPolicyTest < PolicyTest
  setup do
    @comment = create(:comment)
  end

  ['create', 'helpful', 'flag_outdated', 'undo_outdated'].each do |action|
    test action do
      assert_allows_all @comment, action, allow_disabled: false, allow_unverified: false

      # Check that a comment cannot be left on a locked airport
      disabled_airport_comment = create(:comment, airport: create(:airport, locked_at: Time.zone.now))
      assert_denies_all disabled_airport_comment, action

      Rails.configuration.read_only.enable!
      assert_denies_all @comment, action
    ensure
      Rails.configuration.read_only.disable!
    end
  end

  test 'destroy' do
    assert_allows_admin @comment, :destroy
  end
end
