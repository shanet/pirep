require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event)
  end

  test 'create' do
    with_versioning do
      event_attributes = attributes_for(:event, :recurring, airport_id: @event.airport.id, start_date: '2023-11-05T00:00', end_date: '2023-11-06T00:00', data_source: :aopa)

      assert_enqueued_with(job: AirportGeojsonDumperJob) do
        assert_difference('Action.where(type: :event_added).count') do
          post events_path, params: {event: event_attributes}
          assert_redirected_to airport_path(@event.airport.code)
        end
      end

      event = Event.last

      assert_equal event_attributes[:name], event.name, 'Event name not set'
      assert_equal @event.airport, event.airport, 'Event not associated with airport'
      assert_not_nil event.versions.last.whodunnit, 'User not associated with version for webcam'
      assert_equal 'user_contributed', event.data_source, 'Event data source able to be user-controlled'

      # The timestamps above did not have timezone info associated with them so the controller should convert them to the airport's local timezone.
      # These particular dates are on either side of the DST boundary so the hours are different as well.
      assert_equal 7, event.start_date.hour, 'Start date not converted to airport timezone'
      assert_equal 8, event.end_date.hour, 'End date not converted to airport timezone'

      # No recurring fields should be set without the `recurring_event` param set to true
      assert_not event.recurring?, 'Event made recurring without requisite param'
    end
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

    patch event_path(event, params: {'new-event-recurring-toggle' => 'on', event: {recurring_cadence: 'monthly', recurring_week_of_month: 'day_13'}})
    assert_redirected_to airport_path(event.airport.code)

    # Test that the recurring week of month field is parsed correctly when provided with a day-of-month value
    assert_equal 13, event.reload.recurring_day_of_month, 'Recurring week of month field not parsed correctly'
  end

  test 'show - html' do
    get event_path(@event)
    assert_response :no_content
  end

  test 'show - ical static event' do
    get event_path(@event, format: :ical)
    assert_response :success

    assert response.body.include?("SUMMARY:#{@event.name}"), 'ICS file did not contain event name'
    assert response.body.include?("DTSTART:#{@event.next_start_date.iso8601.gsub(/-|:/, '')}"), 'ICS file did not contain event start date'
    assert response.body.include?("DTEND:#{@event.next_end_date.iso8601.gsub(/-|:/, '')}"), 'ICS file did not contain event end date'
    assert response.body.include?("LOCATION:#{@event.location}"), 'ICS file did not contain event location'
    assert response.body.include?("URL:#{@event.url}"), 'ICS file did not contain event URL'
    assert response.body.include?('DESCRIPTION:Visit'), 'ICS file did not contain default description'
    assert_not response.body.include?('RRULE:'), 'ICS file contained recurrance rule for static event'
  end

  test 'show - ical recurring event' do
    event = create(:event, :recurring)

    get event_path(event, format: :ical)
    assert_response :success

    assert response.body.include?('RRULE:'), 'ICS file did not contain recurrance rule for recurring event'
  end

  test 'destroy' do
    with_versioning do
      assert_difference('Action.where(type: :event_removed).where.not(version: nil).count') do
        delete event_path(id: @event)
        assert_redirected_to airport_path(@event.airport.code)
      end
    end
  end
end
