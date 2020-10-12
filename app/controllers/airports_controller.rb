class AirportsController < ApplicationController
  def index
    render json: Airport.geojson.to_json
  end

  def show
    @airport = Airport.find_by(code: params[:id])
    return not_found(request.format.symbol) unless @airport
  end
end
