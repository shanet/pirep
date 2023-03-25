require 'policy_test'

module Manage
  class AttachmentPolicyTest < PolicyTest
    ['index', 'destroy'].each do |action|
      test action do
        assert_allows_admin :manage_attachment, action
      end
    end

    test 'scope' do
      assert_scope([:admin], [:known, :unknown], create(:airport).contributed_photos, ActiveStorage::Attachment)
    end
  end
end
