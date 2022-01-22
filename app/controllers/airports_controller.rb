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
    if @airport.update(airport_params) && @airport.photos.attach(params[:airport][:photos] || [])
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
    # Filter out any tags that are not selected since the UI shows all tags as options to add
    params['airport']&.[]('tags_attributes')&.select! {|index, tag| tag['selected'] == 'true'}

    params.require(:airport).permit(
      :description,
      :transient_parking,
      :fuel_location,
      :landing_fees,
      :crew_car,
      :wifi,
      :landing_rights,
      :landing_requirements,
      tags_attributes: [:name],
    )
  end
end
