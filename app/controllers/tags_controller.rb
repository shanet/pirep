class TagsController < ApplicationController
  def destroy
    @tag = Tag.find(params[:id])
    authorize @tag

    if @tag.destroy
      Action.create!(type: :tag_removed, actionable: @tag, user: active_user, version: @tag.versions.last).persisted?
      render :destroy
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def revert
    version = PaperTrail::Version.find(params[:id])
    authorize(version.item || version.reify)

    case version.event
      when 'create'
        if version.item.destroy
          redirect_to airport_path(version.item.airport), notice: 'Tag removed'
        else # rubocop:disable Style/EmptyElse
          # TODO: error handle
        end
      when 'destroy'
        tag = version.reify

        if tag.save
          redirect_to airport_path(tag.airport), notice: 'Tag added'
        else # rubocop:disable Style/EmptyElse
          # TODO: error handle
        end
    end
  end

private

  def tag_params
    params.require(:tag).permit(:id)
  end
end
