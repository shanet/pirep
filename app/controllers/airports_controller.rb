class AirportsController < ApplicationController
  def index
    render json: Airport.geojson.to_json
  end
end
