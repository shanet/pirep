require 'google/google_api'

class AirportsController < ApplicationController
  def index
    render json: Airport.geojson.to_json
  end

  def show
    @airport = Airport.find_by(code: params[:id])
    @photos = GoogleApi.client.place_photos('%s - %s Airport' % [@airport.code, @airport.name], @airport.latitude, @airport.longitude)
    return not_found(request.format.symbol) unless @airport
  end

  def search
    # Do a very basic match on the airport code for now. TODO: make this an actual search
    results = Airport.where('code LIKE ?', params[:query].upcase).pluck(:code, :name)
    render json: results.map {|airport| {code: airport.first, label: airport.last}}
  end
end
