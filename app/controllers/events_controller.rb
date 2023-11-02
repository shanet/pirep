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
