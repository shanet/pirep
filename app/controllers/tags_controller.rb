class TagsController < ApplicationController
  def destroy
    @tag = Tag.find(params[:id])
    authorize @tag

    if @tag.destroy
      Action.create!(type: :tag_removed, actionable: @tag, user: active_user, version: @tag.versions.last).persisted?
      render :destroy
    else
      render :error_response
    end
  end

  def revert
    version = PaperTrail::Version.find(params[:id])
    authorize(version.item || version.reify)

    case version.event
      when 'create'
        # This is an admin only action and if it fails it's likely something complex that we shouldn't try to gracefully recover from
        version.item.destroy!
        redirect_to airport_path(version.item.airport), notice: 'Tag removed'
      when 'destroy'
        tag = version.reify

        # This is an admin only action and if it fails it's likely something complex that we shouldn't try to gracefully recover from
        tag.save!
        redirect_to airport_path(tag.airport), notice: 'Tag added'
    end
  end

private

  def tag_params
    params.require(:tag).permit(:id)
  end
end
