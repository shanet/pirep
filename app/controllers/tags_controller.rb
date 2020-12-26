class TagsController < ApplicationController
  def destroy
    tag = Tag.find(params[:id])

    if tag.destroy
      redirect_to airport_path(tag.airport.code)
    else
      # TODO: error handle
    end
  end

private

  def tag_params
    params.require(:tag).permit(:id)
  end
end
