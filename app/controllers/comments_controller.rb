class CommentsController < ApplicationController
  before_action :set_comment, only: [:helpful, :flag_outdated, :undo_outdated, :destroy]

  def create
    comment = Comment.new(comment_params)
    authorize comment

    if comment.save
      redirect_to airport_path(comment.airport.code), notice: 'Comment posted successfully'
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def helpful
    @comment.helpful_count += 1

    if @comment.save
      render :helpful
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def flag_outdated
    @comment.outdated_at = Time.zone.now

    if @comment.save
      render :flag_outdated
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def undo_outdated
    @comment.outdated_at = nil

    if @comment.save
      render :undo_outdated
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def destroy
    if @comment.destroy
      redirect_to airport_path(@comment.airport), notice: 'Comment deleted successfully'
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

private

  def set_comment
    @comment = Comment.find(params[:id])
    authorize @comment
  end

  def comment_params
    params.require(:comment).permit(:body, :airport_id)
  end
end
