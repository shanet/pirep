class TagsController < ApplicationController
  def destroy
    @tag = Tag.find(params[:id])

    if @tag.destroy
      render :destroy
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

private

  def tag_params
    params.require(:tag).permit(:id)
  end
end
