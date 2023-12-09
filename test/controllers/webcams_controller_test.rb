require 'test_helper'

class WebcamsControllerTest < ActionDispatch::IntegrationTest
  test 'create' do
    with_versioning do
      url = 'https://example.com/webcam.jpg'

      assert_difference('Action.where(type: :webcam_added).count') do
        post webcams_path, params: {webcam: {airport_id: create(:airport).id, url: url}}
        assert_response :redirect
      end

      assert_equal url, Webcam.last.url, 'URL not set for webcam'
      assert_not_nil Webcam.last.versions.last.whodunnit, 'User not associated with version for webcam'

      assert_in_delta Time.zone.now, Users::Unknown.last.last_seen_at, 1.second, 'Unknown user\'s last seen at timestamp not set after creating webcam'
      assert_in_delta Time.zone.now, Users::Unknown.last.last_edit_at, 1.second, 'Unknown user\'s last edit at timestamp not set after creating webcam'
    end
  end

  test 'destroy' do
    webcam = create(:webcam)

    with_versioning do
      assert_difference('Webcam.count', -1) do
        assert_difference('Action.where(type: :webcam_removed).where.not(version: nil).count') do
          delete webcam_path(id: webcam)
          assert_redirected_to airport_path(webcam.airport.code)
        end
      end
    end
  end
end
