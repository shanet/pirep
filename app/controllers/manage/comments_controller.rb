class Manage::CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  def index
    @comments = Comment.order(:created_at).page(params[:page])
    authorize @comments, policy_class: Manage::CommentPolicy
  end

  def show
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      if request.xhr?
        @record_id = @comment.id
        render 'shared/manage/remove_review_record'
      else
        redirect_to manage_comment_path(@comment), notice: 'Comment updated successfully'
      end
    elsif request.xhr?
      render 'shared/manage/remove_review_record_error'
    else
      render :edit
    end
  end

  def destroy
    if @comment.destroy
      redirect_to manage_comments_path, notice: 'Comment deleted successfully'
    else
      redirect_to manage_comment_path(@comment), alert: 'Failed to delete comment'
    end
  end

private

  def set_comment
    @comment = Comment.find(params[:id])
    authorize @comment, policy_class: Manage::CommentPolicy
  end

  def comment_params
    return params.require(:comment).permit(:body, :helpful_count, :reviewed_at)
  end
end
