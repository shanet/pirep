class Manage::VersionsController < ApplicationController
  before_action :set_version

  def update
    if @version.update(version_params)
      if request.xhr?
        @record_id = @version.id
        render 'shared/manage/remove_review_record'
      else
        redirect_to history_airport_path(airport_for_version(@version)), notice: 'Revision updated successfully'
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
    return params.expect(version: [:reviewed_at])
  end

  def airport_for_version(version)
    if version.item_type == Tag.name
      return (version.event == 'destroy' ? version.object['airport_id'] : version.item.airport)
    end

    return version.item
  end
end
