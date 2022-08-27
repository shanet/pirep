require 'test_helper'

class MapControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    get root_path
    assert_response :success
  end
end
