class CommentsController < ApplicationController
  before_action :set_comment, only: [:helpful, :flag_outdated]

  def create
    comment = Comment.new(comment_params)

    if comment.save
      redirect_to airport_path(comment.airport.code)
    else
      # TODO: error handle
    end
  end

  def helpful
    @comment.helpful_count += 1

    if @comment.save
      render :helpful
    else
      # TODO: error handle
    end
  end

  def flag_outdated
    @comment.outdated_at = Time.zone.now

    if @comment.save
      head :ok
    else
      # TODO: error handle
    end
  end

private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :airport_id)
  end
end
