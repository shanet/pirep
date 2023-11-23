require 'test_helper'
require 'aopa/aopa_api'

class AopaApiTest < ActiveSupport::TestCase
  setup do
    @client = AopaApi.client
  end

  test 'fetches events' do
    travel_to(Time.zone.parse('2023-11-01')) do
      events = @client.fetch_events

      assert_equal 1, events.count, 'Unexpected number of events'
      assert_equal 'Test Event', events.first[:name], 'Unexpected event name'
      assert_equal 47.925284, events.first[:latitude], 'Unexpected event latitude'
      assert_equal(-122.272657, events.first[:longitude], 'Unexpected event longitude')
      assert_equal 'Everett', events.first[:city], 'Unexpected event city'
      assert_equal 'WA', events.first[:state], 'Unexpected event state'
      assert_in_delta Time.zone.parse('2023-11-05 20:00:00 UTC').in_time_zone('America/Los_Angeles'), events.first[:start_date], 1.second, 'Unexpected event start date'
      assert_in_delta Time.zone.parse('2023-11-05 21:00:00 UTC').in_time_zone('America/Los_Angeles'), events.first[:end_date], 1.second, 'Unexpected event start date'
      assert events.first[:digest].blank?, 'Event has digest'
    end
  end
end
