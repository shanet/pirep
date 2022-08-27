class Manage::AirportsController < ApplicationController
  before_action :set_airport, only: [:show, :edit, :update]

  def index
    @airports = Airport.order(:code).page(params[:page])
    authorize @airports, policy_class: Manage::AirportPolicy
  end

  def show
  end

  def edit
  end

  def update
    @airport.update!(airport_params)
    redirect_to manage_airport_path(@airport)
  end

private

  def set_airport
    @airport = Airport.find(params[:id])
    authorize @airport, policy_class: Manage::AirportPolicy
  end

  def airport_params
    return params.require(:airport).permit(:name)
  end
end
