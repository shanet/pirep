require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'create' do
    post comments_path, params: {comment: {airport_id: create(:airport).id, body: 'Hello, world!'}}
    assert_response :redirect
  end

  test 'helpful' do
    comment = create(:comment)
    post helpful_comment_path(comment, format: :js)
    assert_response :success
  end

  test 'flag_outdated' do
    comment = create(:comment)
    post flag_outdated_comment_path(comment, format: :js)
    assert_response :success
  end

  test 'undo_outdated' do
    comment = create(:comment)
    post undo_outdated_comment_path(comment, format: :js)
    assert_response :success
  end
end
