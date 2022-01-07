require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  test 'destroy' do
    delete tag_path(id: create(:tag), format: :js)
    assert_response :success
  end
end
