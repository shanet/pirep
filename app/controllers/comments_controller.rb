class CommentsController < ApplicationController
  before_action :set_comment, only: [:helpful, :flag_outdated, :undo_outdated, :destroy]

  def create
    comment = Comment.new(comment_params.merge(user: active_user))
    authorize comment

    if comment.save && Action.create(type: :comment_added, actionable: comment, user: active_user).persisted?
      touch_user_edit
      redirect_to airport_path(comment.airport.code), notice: 'Comment posted successfully'
    else
      redirect_to airport_path(comment.airport.code), alert: "Error posting comment: #{comment.errors.full_messages.join("\n")}"
    end
  end

  def helpful
    # Don't increment helpful count if the user already found it helpful
    forbidden if @comment.found_helpful?(active_user)

    if @comment.update(helpful_count: @comment.helpful_count + 1) && Action.create(type: :comment_helpful, actionable: @comment, user: active_user).persisted?
      touch_user_edit
      render :helpful
    else
      render :error_response
    end
  end

  def flag_outdated
    if @comment.update(outdated_at: Time.zone.now) && Action.create(type: :comment_flagged, actionable: @comment, user: active_user).persisted?
      touch_user_edit
      render :flag_outdated
    else
      render :error_response
    end
  end

  def undo_outdated
    if @comment.update(outdated_at: nil) && Action.create(type: :comment_unflagged, actionable: @comment, user: active_user).persisted?
      touch_user_edit
      render :undo_outdated
    else
      render :error_response
    end
  end

  def destroy
    # This is an admin-only action, let it fail loudly if needed
    @comment.destroy!
    redirect_to airport_path(@comment.airport), notice: 'Comment deleted successfully'
  end

private

  def set_comment
    @comment = Comment.find(params[:id])
    authorize @comment
  end

  def comment_params
    return params.require(:comment).permit(:body, :airport_id)
  end
end
