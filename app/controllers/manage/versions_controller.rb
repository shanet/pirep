class Manage::VersionsController < ApplicationController
  before_action :set_version

  def update
    if @version.update(version_params)
      if request.xhr?
        @record_id = @version.id
        render 'shared/manage/remove_review_record'
      else
        airport = (@version.item_type == Tag.name ? @version.item.airport : @version.item)
        redirect_to history_airport_path(airport), notice: 'Revision updated successfully'
      end
    elsif request.xhr?
      render 'shared/manage/remove_review_record_error'
    else
      redirect_to history_airport_path(@version.item), alert: 'Failed to update version'
    end
  end

private

  def set_version
    @version = PaperTrail::Version.find(params[:id])
    authorize @version, policy_class: Manage::VersionPolicy
  end

  def version_params
    return params.require(:version).permit(:reviewed_at)
  end
end
