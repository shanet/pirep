class EventsController < ApplicationController
  before_action :set_event, only: [:edit, :update, :destroy]

  def create
    @event = Event.new(event_params)
    authorize @event

    # Events created through the UI are always user contributed
    @event.data_source = :user_contributed

    if @event.save && Action.create(type: :event_added, actionable: @event, user: active_user).persisted?
      touch_user_edit

      # Schedule an airport cache refresh so the event's airport shows up on the map as tagged with "events"
      AirportGeojsonDumperJob.perform_later

      redirect_to airport_path(@event.airport.code), notice: 'Event created successfully'
    else
      render :edit, layout: 'blank'
    end
  end

  def edit
    render :edit, layout: 'blank'
  end

  def update
    if @event.update(event_params) && Action.create(type: :event_edited, actionable: @event, user: active_user).persisted?
      touch_user_edit
      redirect_to airport_path(@event.airport.code), notice: 'Event updated successfully'
    else
      render :edit, layout: 'blank'
    end
  end

  def destroy
    if @event.destroy && Action.create(type: :event_removed, actionable: @event, user: active_user, version: @event.versions.last).persisted?
      touch_user_edit
      redirect_to airport_path(@event.airport.code), notice: 'Event deleted successfully'
    else
      render :edit, layout: 'blank'
    end
  end

private

  def set_event
    @event = Event.find(params[:id])
    authorize @event
  end

  def event_params
    # If the event is not recurring then disregard all of the recurring fields
    unless params['new-event-recurring-toggle'] == 'on'
      [:recurring_cadence, :recurring_day_of_month, :recurring_interval, :recurring_week_of_month].each do |field|
        params[:event][field] = nil
      end
    end

    # Split out the day/week of month value into two separate fields since these are from the same select element
    week_of_month = params[:event][:recurring_week_of_month]&.split('_')

    if week_of_month&.first == 'day'
      params[:event][:recurring_day_of_month] = week_of_month.last.to_i
      params[:event][:recurring_week_of_month] = nil
    elsif week_of_month&.first == 'week'
      params[:event][:recurring_week_of_month] = week_of_month.last.to_i
      params[:event][:recurring_day_of_month] = nil
    end

    # Put the start/end dates in the timezone local to the event's airport
    if params[:event][:start_date].present? || params[:event][:end_date].present?
      timezone = (params[:event][:airport_id] ? Airport.find(params[:event][:airport_id]).timezone : Rails.configuration.time_zone)

      params[:event][:start_date] = params[:event][:start_date]&.in_time_zone(timezone) if params[:event][:start_date].present?
      params[:event][:end_date] = params[:event][:end_date]&.in_time_zone(timezone) if params[:event][:end_date].present?
    end

    return params.require(:event).permit(
      :airport_id,
      :description,
      :end_date,
      :host,
      :location,
      :name,
      :recurring_cadence,
      :recurring_day_of_month,
      :recurring_interval,
      :recurring_week_of_month,
      :start_date,
      :url
    )
  end
end
