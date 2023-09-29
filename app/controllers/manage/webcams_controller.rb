class Manage::WebcamsController < ApplicationController
  before_action :set_webcam, only: :destroy

  def destroy
    if @webcam.destroy
      redirect_to manage_airport_path(@webcam.airport), notice: 'Webcam deleted successfully'
    else
      redirect_to manage_airport_path(@webcam.airport)
    end
  end

private

  def set_webcam
    @webcam = Webcam.find(params[:id])
    authorize @webcam, policy_class: Manage::WebcamPolicy
  end
end
