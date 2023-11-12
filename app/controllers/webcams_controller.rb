class WebcamsController < ApplicationController
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

private

  def webcam_params
    params.require(:webcam).permit(:airport_id, :url)
  end
end
