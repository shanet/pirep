require 'test_helper'

class Manage::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @comment = create(:comment)
    sign_in :admin
  end

  test 'index' do
    get manage_comments_path
    assert_response :success
  end

  test 'show' do
    get manage_comment_path(@comment)
    assert_response :success
  end

  test 'edit' do
    get edit_manage_comment_path(@comment)
    assert_response :success
  end

  test 'update' do
    patch manage_comment_path(@comment, params: {comment: {body: 'foo'}})
    assert_redirected_to manage_comment_path(@comment)
  end

  test 'destroy' do
    assert_difference('Comment.count', -1) do
      delete manage_comment_path(@comment)
      assert_redirected_to manage_comments_path
    end
  end
end
