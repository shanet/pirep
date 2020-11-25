require 'google/google_api'

class AirportsController < ApplicationController
  before_action :set_airport, only: :update

  def index
    render json: Airport.geojson.to_json
  end

  def show
    @airport = Airport.find_by(code: params[:id].upcase)
    return not_found(request.format.symbol) unless @airport

    @photos = GoogleApi.client.place_photos('%s - %s Airport' % [@airport.code, @airport.name], @airport.latitude, @airport.longitude)
  end

  def update
    if @airport.update(airport_params)
      head :ok
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
    params.require(:airport).permit(
      :description,
      :transient_parking,
    )
  end
end
