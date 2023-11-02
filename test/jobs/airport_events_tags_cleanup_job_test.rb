require 'test_helper'

class AirportEventsTagsCleanupJobTest < ActiveJob::TestCase
  setup do
    @airport = create(:airport)
    @recurring_event = create(:event, :recurring, airport: @airport)
    create(:event, airport: @airport)
  end

  test 'removes tag from airport' do
    assert_equal 1, @airport.tags.where(name: :events).count, 'Airport not tagged with events'

    # The events tag should not be removed if there is an upcoming recurring event
    AirportEventsTagsCleanupJob.perform_now
    assert_equal 1, @airport.tags.where(name: :events).count, 'Airport not tagged with events'

    # The events tag should be removed if the only events are in the past
    @recurring_event.destroy!
    AirportEventsTagsCleanupJob.perform_now
    assert_equal 0, @airport.tags.where(name: :events).count, 'Airport not tagged with events'
  end
end
