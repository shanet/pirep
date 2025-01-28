class TagsController < ApplicationController
  def destroy
    @tag = Tag.find(params[:id])
    authorize @tag

    if @tag.destroy && Action.create(type: :tag_removed, actionable: @tag, user: active_user, version: @tag.versions.last).persisted?
      touch_user_edit

      # Schedule a geojson dump so the tag is removed from the map
      AirportGeojsonDumperJob.perform_later

      render :destroy
    else
      render :error_response
    end
  end

private

  def tag_params
    params.expect(tag: [:id])
  end
end
