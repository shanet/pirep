require 'test_helper'

class Manage::AttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport)
    sign_in :admin
  end

  test 'index' do
    get manage_attachments_path
    assert_response :success
  end

  test 'destroy' do
    assert_difference('ActiveStorage::Attachment.count', -1) do
      delete manage_attachment_path(@airport.contributed_photos.first)
      assert_redirected_to manage_attachments_path
    end
  end
end
