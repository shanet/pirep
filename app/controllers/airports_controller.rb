class AirportsController < ApplicationController
  before_action :set_airport, only: :update

  def index
    render json: Airport.geojson.to_json
  end

  def show
    @airport = Airport.find_by(code: params[:id].upcase) || Airport.find_by(code: params[:id].upcase.gsub(/^K/, '')) || Airport.find(params[:id])
    return not_found(request.format.symbol) unless @airport
  end

  def update
    if @airport.update(airport_params)
      if request.xhr?
        head :ok
      else
        redirect_to airport_path(@airport.code)
      end
    else
      # TODO: error handle
    end
  end

  def search
    # Do a very basic match on the airport code for now. TODO: make this an actual search
    results = Airport.where('code LIKE ?', params[:query].upcase).pluck(:code, :name)
    render json: results.map {|airport| {code: airport.first, label: airport.last}}
  end

private

  def set_airport
    @airport = Airport.find(params[:id])
  end

  def airport_params
    # The landing requirements field may be split over multiple text fields for each landing right type so we need to find the one for the selected landing right type
    params[:airport][:landing_requirements] ||= params[:airport]["landing_requirements_#{params[:airport][:landing_rights]}"]

    # Filter out any tags that are not selected since the UI shows all tags as options to add
    params['airport']['tags_attributes']&.select! {|index, tag| tag['selected'] == 'true'}

    params.require(:airport).permit(
      :description,
      :transient_parking,
      :landing_rights,
      :landing_requirements,
      photos: [],
      tags_attributes: [:name],
    )
  end
end
