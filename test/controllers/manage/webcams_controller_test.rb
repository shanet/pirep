require 'test_helper'

class Manage::WebcamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @webcam = create(:webcam)
    sign_in :admin
  end

  test 'destroy' do
    assert_difference('Webcam.count', -1) do
      delete manage_webcam_path(@webcam)
      assert_redirected_to manage_airport_path(@webcam.airport)
    end
  end
end
