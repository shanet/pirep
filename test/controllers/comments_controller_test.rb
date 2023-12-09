require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'create' do
    user = create(:known)
    sign_in user

    assert_difference('Action.where(type: :comment_added).count') do
      post comments_path, params: {comment: {airport_id: create(:airport).id, body: 'Hello, world!'}}
      assert_response :redirect
    end

    assert_equal user, Comment.last.user, 'User not set for comment'

    assert_in_delta Time.zone.now, user.reload.last_seen_at, 1.second, 'Unknown user\'s last seen at timestamp not set after creating comment'
    assert_in_delta Time.zone.now, user.reload.last_edit_at, 1.second, 'Unknown user\'s last edit at timestamp not set after creating comment'
  end

  test 'helpful' do
    comment = create(:comment)

    assert_difference('Action.where(type: :comment_helpful).count') do
      patch helpful_comment_path(comment, format: :js)
      assert_response :success
    end
  end

  test 'flag_outdated' do
    comment = create(:comment)

    assert_difference('Action.where(type: :comment_flagged).count') do
      patch flag_outdated_comment_path(comment, format: :js)
      assert_response :success
    end
  end

  test 'undo_outdated' do
    comment = create(:comment)

    assert_difference('Action.where(type: :comment_unflagged).count') do
      patch undo_outdated_comment_path(comment, format: :js)
      assert_response :success
    end
  end

  test 'destroy' do
    sign_in create(:admin)
    comment = create(:comment)

    assert_difference('Comment.count', -1) do
      delete comment_path(comment)
      assert_response :redirect
    end
  end
end
