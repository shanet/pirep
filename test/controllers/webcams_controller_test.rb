require 'test_helper'

class WebcamsControllerTest < ActionDispatch::IntegrationTest
  test 'create' do
    url = 'https://example.com/webcam.jpg'

    assert_difference('Action.where(type: :webcam_added).count') do
      post webcams_path, params: {webcam: {airport_id: create(:airport).id, url: url}}
      assert_response :redirect
    end

    assert_equal url, Webcam.last.url, 'URL not set for webcam'
  end
end
