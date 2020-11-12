class TagsController < ApplicationController
  def create
    tag = Tag.new(tag_params)

    if tag.save
      redirect_to airport_path(tag.airport.code)
    else
      # TODO: error handle
    end
  end

private

  def tag_params
    params.require(:tag).permit(:name, :airport_id)
  end
end
