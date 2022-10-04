class Manage::AirportsController < ApplicationController
  include SearchQueryable
  before_action :set_airport, only: [:show, :edit, :update, :update_version]

  def index
    @airports = Airport.order(:code).page(params[:page])
    authorize @airports, policy_class: Manage::AirportPolicy
  end

  def search
    results = Search.query(preprocess_query, Airport, wildcard: true)

    @total_records = results.count(Airport.table_name)
    @airports = results.page(params[:page])
    authorize @airports, policy_class: Manage::AirportPolicy
  end

  def show
  end

  def edit
    flash.now[:warning] = 'Warning: It\'s probably a bad idea to be editing an airport\'s values. This is typically only useful to correct manually created unmapped airports.'
  end

  def update
    if @airport.update(airport_params)
      redirect_to manage_airport_path(@airport), notice: 'Airport updated successfully'
    else
      render :edit
    end
  end

  def update_version
    if PaperTrail::Version.find(params[:version_id]).update(version_params)
      if request.xhr?
        @record_id = params[:version_id]
        render 'shared/manage/remove_review_record'
      else
        redirect_to history_airport_path(@airport), notice: 'Revision updated successfully'
      end
    elsif request.xhr?
      render 'shared/manage/remove_review_record_error'
    else
      redirect_to history_airport_path(@airport), alert: 'Failed to update version'
    end
  end

private

  def set_airport
    @airport = Airport.find(params[:id])
    authorize @airport, policy_class: Manage::AirportPolicy
  end

  def airport_params
    return params.require(:airport).permit(:code, :name, :fuel_type, :latitude, :longitude, :elevation, :facility_type, :facility_use, :ownership_type, :owner_name, :owner_phone)
  end

  def version_params
    return params.require(:version).permit(:reviewed_at)
  end
end
