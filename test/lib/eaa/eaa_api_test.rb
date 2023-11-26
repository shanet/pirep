require 'test_helper'
require 'eaa/eaa_api'

class EaaApiTest < ActiveSupport::TestCase
  setup do
    @client = EaaApi.client
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
      assert_equal '2023-11-14T11:00:00', events.first[:start_date], 'Unexpected event start date'
      assert_equal '2023-11-14T11:00:00', events.first[:end_date], 'Unexpected event start date'
      assert events.first[:digest].present?, 'Event has no digest'
    end
  end
end
