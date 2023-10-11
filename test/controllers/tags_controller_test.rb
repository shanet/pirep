require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  test 'destroy' do
    assert_difference('Action.where(type: :tag_removed).count') do
      assert_enqueued_with(job: AirportGeojsonDumperJob) do
        delete tag_path(id: create(:tag), format: :js)
        assert_response :success
      end
    end
  end
end
