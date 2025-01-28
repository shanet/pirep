class WebcamsController < ApplicationController
  before_action :set_webcam, only: :destroy

  def create
    webcam = Webcam.new(webcam_params)
    authorize webcam

    if webcam.save && Action.create(type: :webcam_added, actionable: webcam, user: active_user, version: webcam.versions.last).persisted?
      touch_user_edit
      redirect_to airport_path(webcam.airport.code), notice: 'Webcam added successfully'
    else
      redirect_to airport_path(webcam.airport.code), alert: "Error adding webcam: #{webcam.errors.full_messages.join("\n")}"
    end
  end

  def destroy
    if @webcam.destroy && Action.create(type: :webcam_removed, actionable: @webcam, user: active_user, version: @webcam.versions.last).persisted?
      redirect_to airport_path(@webcam.airport.code), notice: 'Webcam deleted successfully'
    else
      redirect_to airport_path(@webcam.airport.code)
    end
  end

private

  def webcam_params
    params.expect(webcam: [:airport_id, :url])
  end

  def set_webcam
    @webcam = Webcam.find(params[:id])
    authorize @webcam
  end
end
