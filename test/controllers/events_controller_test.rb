require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event)
  end

  test 'create' do
    event_attributes = attributes_for(:event, airport_id: @event.airport.id, start_date: '2023-11-05T00:00', end_date: '2023-11-06T00:00')

    assert_difference('Action.where(type: :event_added).count') do
      post events_path, params: {event: event_attributes}
      assert_redirected_to airport_path(@event.airport.code)
    end

    event = Event.last

    assert_equal event_attributes[:name], event.name, 'Event name not set'
    assert_equal @event.airport, event.airport, 'Event not associated with airport'

    # The timestamps above did not have timezone info associated with them so the controller should convert them to the airport's local timezone.
    # These particular dates are on either side of the DST boundary so the hours are different as well.
    assert_equal 7, event.start_date.hour, 'Start date not converted to airport timezone'
    assert_equal 8, event.end_date.hour, 'End date not converted to airport timezone'
  end

  test 'edit' do
    get edit_event_path(@event)
    assert_response :success
  end

  test 'update' do
    event = create(:event, :recurring)

    assert_difference('Action.where(type: :event_edited).count') do
      patch event_path(event, params: {event: {name: 'foo'}})
      assert_redirected_to airport_path(event.airport.code)
    end

    # Not giving a recurring cadence assumes that the event is to be updated to non-recurring
    assert_nil event.reload.recurring_cadence, 'Recurring event not set to non-recurring'
  end

  test 'update recurring event' do
    event = create(:event, :recurring)

    patch event_path(event, params: {event: {recurring_cadence: 'monthly', recurring_week_of_month: 'day_13'}})
    assert_redirected_to airport_path(event.airport.code)

    # Test that the recurring week of month field is parsed correctly when provided with a day-of-month value
    assert_equal 13, event.reload.recurring_day_of_month, 'Recurring week of month field not parsed correctly'
  end

  test 'destroy' do
    assert_difference('Action.where(type: :event_removed).count') do
      delete event_path(id: @event)
      assert_redirected_to airport_path(@event.airport.code)
    end
  end
end