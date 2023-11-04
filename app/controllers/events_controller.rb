class EventsController < ApplicationController
  before_action :set_event, only: [:edit, :update, :destroy]

  def create
    @event = Event.new(event_params)
    authorize @event

    if @event.save && Action.create(type: :event_added, actionable: @event, user: active_user).persisted?
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
      redirect_to airport_path(@event.airport.code), notice: 'Event updated successfully'
    else
      render :edit, layout: 'blank'
    end
  end

  def destroy
    if @event.destroy && Action.create(type: :event_removed, actionable: @event, user: active_user).persisted?
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
    unless params[:recurring_event] == '1'
      [:recurring_cadence, :recurring_day_of_month, :recurring_interval, :recurring_week_of_month].each do |field|
        params[:event].delete(field)
      end
    end

    week_of_month = params[:event][:recurring_week_of_month]&.split('_')

    # Split out the day/week of month value into two separate fields since these are from the same select element
    if week_of_month&.first == 'day'
      params[:event][:recurring_day_of_month] = week_of_month.last.to_i
      params[:event].delete(:recurring_week_of_month)
    elsif week_of_month&.first == 'week'
      params[:event][:recurring_week_of_month] = week_of_month.last.to_i
    end

    # If no recurring cadence value was provided assume the event if non-recurring (for changing a recurring event to a non-recurring one)
    params[:event][:recurring_cadence] ||= nil

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
