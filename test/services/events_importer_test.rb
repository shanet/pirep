require 'test_helper'

class EventsImporterTest < ActiveSupport::TestCase
  # Events with start times in the past are filtered out so in order to import an event with the fixed test fixtures we need to travel to a date before those fixtures
  TIME_TRAVEL_DATE = Time.zone.parse('2023-11-01')

  test 'imports events' do
    # Create an airport to match the events to (otherwise they won't be created)
    airport = create(:airport)

    import_events!

    ['aopa', 'eaa'].each do |data_source|
      event = Event.find_by(data_source: data_source)

      assert_equal 'Test Event', event.name, 'Unexpected event name'
      assert_equal airport, event.airport, 'Event not associated with airport'
      assert_equal data_source, event.data_source, 'Unexpected event data source'
      assert_not event.recurring?, 'Event marked as recurring'
      assert_not_nil event.digest, 'Event digest not set'

      case data_source
        when 'aopa'
          assert_in_delta Time.zone.parse('2023-11-05 20:00:00 UTC'), event.start_date, 1.second, 'Event start date not in airport\'s timezone'
          assert_in_delta Time.zone.parse('2023-11-05 21:00:00 UTC'), event.end_date, 1.second, 'Event end date not in airport\'s timezone'
        when 'eaa'
          assert_in_delta Time.zone.parse('2023-11-14 19:00:00 UTC'), event.start_date, 1.second, 'Event start date not in airport\'s timezone'
          assert_in_delta Time.zone.parse('2023-11-14 20:00:00 UTC'), event.end_date, 1.second, 'Event end date not in airport\'s timezone'
      end
    end
  end

  test 'matches event to public airport in given city/state' do
    # The event should be matched to a public airport with a matching city/state even when another public airport is closer
    airport = create(:airport)
    create(:airport, city: 'SNOHOMISH', state: 'WA', latitude: 47.925284, longitude: -122.272657)

    import_events!

    assert_equal airport, Event.last.airport, 'Event not associated with airport in city/state'
  end

  test 'matches event to public airport without city/state' do
    # The event should be matched to a public airport even when a private airport is closer
    public_airport = create(:airport)
    create(:airport, facility_use: 'PR', latitude: 47.925284, longitude: -122.272657)

    import_events!

    assert_equal public_airport, Event.last.airport, 'Event not associated with public airport'
  end

  test 'does not match events to heliports' do
    # The event should be matched to an airport even when a heliport is closer
    airport = create(:airport)
    create(:airport, facility_type: :heliport, latitude: 47.925284, longitude: -122.272657)

    import_events!

    assert_equal airport, Event.last.airport, 'Event not associated with airport'
  end

  test 'matches event to private airport' do
    # The event should be matched with a private airport only when no public airports are within the search radius
    create(:airport, latitude: 42.0, longitude: -122.0)
    private_airport = create(:airport, facility_use: 'PR')

    import_events!

    assert_equal private_airport, Event.last.airport, 'Event not associated with private airport'
  end

  test 'ignores event without matching airport' do
    create(:airport, latitude: 42.0, longitude: -122.0)

    import_events!(expected_count: 0)
  end

  test 'does not re-import duplicate events' do
    create(:airport)

    import_events!

    travel_to(TIME_TRAVEL_DATE) do
      assert_difference('Event.count', 0) do
        EventsImporter.new.import!
      end
    end
  end

  test 'filters out past events' do
    # The event in the stubs has a start date of November 2023. Any test runs after this date should filter it out.
    assert_difference('Event.count', 0) do
      EventsImporter.new.import!
    end
  end

private

  def import_events!(expected_count: 2)
    travel_to(TIME_TRAVEL_DATE) do
      assert_difference('Event.count', expected_count) do
        EventsImporter.new.import!
      end
    end
  end
end
