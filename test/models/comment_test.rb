require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    @comment = create(:comment)
  end

  test 'found_helpful?' do
    action = create(:action, type: :comment_helpful, actionable: @comment)
    assert @comment.found_helpful?(action.user), 'User did not find comment helpful'
  end
end
