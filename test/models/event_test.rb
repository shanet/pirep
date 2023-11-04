require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test 'is a recurring event' do
    assert_not create(:event).recurring?, 'Non-recurring event marked as recurring'
    assert create(:event, :recurring).recurring?, 'Recurring event not marked as recurring'
  end

  test 'recurring cadence returns a symbol' do
    event = create(:event, :recurring)
    assert_equal event.recurring_cadence.to_sym, event.recurring_cadence, 'Recurring cadence not returned as a symbol'
  end

  test 'upcoming events' do
    create(:event, start_date: 1.month.ago, end_date: 1.month.ago + 1.hour)
    upcoming_event = create(:event, start_date: 1.month.from_now, end_date: 1.month.from_now + 1.hour)

    assert_equal 1, Event.upcoming.count, 'Wrong number of upcoming events'
    assert_equal upcoming_event, Event.upcoming.first, 'Incorrect event found as upcoming'
  end

  test 'next start date for static event' do
    event = create(:event)
    assert_equal event.start_date, event.next_start_date, 'Wrong next start date for static event'
  end

  test 'next end date for static event' do
    event = create(:event)
    assert_equal event.end_date, event.next_end_date, 'Wrong next end date for static event'
  end

  # This is a difficult method to test without replicating a bunch of logic from the ice_cube gem to calculate
  # the expected start date so instead just do some basic sanity checks on recurring events of various types
  test 'next start date for recurring event' do
    event = create(:event, :recurring, start_date: 1.day.ago, end_date: 1.day.ago + 1.hour, recurring_cadence: :daily)
    assert_in_delta 1.day.from_now, event.next_start_date, 1.day, 'Unexpected next start date for daily recurring event'

    event = create(:event, :recurring, start_date: 5.days.from_now, end_date: 6.days.from_now, recurring_cadence: :daily)
    assert_in_delta 5.days.from_now, event.next_start_date, 1.day, 'Unexpected next start date for daily recurring event'

    event = create(:event, :recurring, start_date: 1.day.ago, end_date: Time.zone.now, recurring_cadence: :weekly, recurring_interval: 2)
    assert_in_delta 2.weeks.from_now, event.next_start_date, 1.week, 'Unexpected next start date for weekly recurring event'

    event = create(:event, :recurring, start_date: Time.zone.now, end_date: 2.days.from_now, recurring_cadence: :monthly, recurring_day_of_month: 15)
    assert_in_delta 1.month.from_now, event.next_start_date, 1.month, 'Unexpected next start date for monthly day-of-month recurring event'

    event = create(:event, :recurring, start_date: Time.zone.now, end_date: 2.days.from_now, recurring_cadence: :monthly, recurring_week_of_month: 3)
    assert_in_delta 1.month.from_now, event.next_start_date, 1.month, 'Unexpected next start date for monthly week-of-month recurring event'

    event = create(:event, :recurring, start_date: 3.months.ago, end_date: 2.days.from_now, recurring_cadence: :yearly, recurring_day_of_month: 5)
    assert_in_delta 1.year.from_now - 3.months, event.next_start_date, 1.month, 'Unexpected next start date for yearly day-of-month recurring event'

    event = create(:event, :recurring, start_date: 3.months.from_now, end_date: 4.months.from_now, recurring_cadence: :yearly, recurring_week_of_month: 2)
    assert_in_delta 3.months.from_now, event.next_start_date, 1.month, 'Unexpected next start date for yearly week-of-month recurring event'
  end

  test 'next end date for recurring event' do
    event = create(:event, :recurring, start_date: 1.day.from_now, end_date: 3.days.from_now + 1.hour, recurring_cadence: :daily)

    # The next end date for a recurring event spread over multiple days should be equal to the next start date + the difference between the start and end dates
    assert_equal event.next_start_date + (event.end_date - event.start_date), event.next_end_date, 'End date for recurring event incorrect'
  end

  test 'next start date for DST boundary' do
    event = create(:event, :recurring, start_date: Time.zone.local(2023, 11, 1), end_date: Time.zone.local(2023, 11, 2), recurring_cadence: :monthly)

    start_date = event.start_date.in_time_zone(event.airport.timezone)
    end_date = event.end_date.in_time_zone(event.airport.timezone)
    next_start_date = event.next_start_date.in_time_zone(event.airport.timezone)
    next_end_date = event.next_end_date.in_time_zone(event.airport.timezone)

    assert start_date.dst?, 'Event not starting during DST'
    assert_not next_start_date.dst?, 'Event\'s next start date still during DST'
    assert_equal start_date.hour, next_start_date.hour, 'Cross-DST hours not adjusted for recurring event start'
    assert_equal end_date.hour, next_end_date.hour, 'Cross-DST hours not adjusted for recurring event end'
  end

  test 'day/week of month is required for monthly/yearly recurring event' do
    assert create(:event, recurring_interval: 1, recurring_cadence: :monthly, recurring_day_of_month: 1).valid?, 'Recurring event invalid'
    assert create(:event, recurring_interval: 1, recurring_cadence: :yearly, recurring_week_of_month: 1).valid?, 'Recurring event invalid'
    assert create(:event, recurring_interval: 1, recurring_cadence: :daily, recurring_day_of_month: nil).valid?, 'Recurring event invalid'

    assert_raises(ActiveRecord::RecordInvalid) {create(:event, recurring_interval: 1, recurring_cadence: :monthly, recurring_week_of_month: nil)}
    assert_raises(ActiveRecord::RecordInvalid) {create(:event, recurring_interval: 1, recurring_cadence: :yearly, recurring_day_of_month: nil)}
  end

  test 'adds event tag to airport' do
    airport = create(:airport)
    assert airport.tags.where(name: :events).empty?, 'Airport already has events tag'

    create(:event, airport: airport)
    assert airport.tags.where(name: :events).any?, 'Events tag not added to airport'
  end

  test 'removes event tag from airport' do
    airport = create(:airport)
    event1 = create(:event, airport: airport)
    event2 = create(:event, airport: airport)

    # The events tags should only be removed when the last event on the airport is deleted
    event1.destroy!
    assert airport.tags.where(name: :events).any?, 'Events tag removed from airport'

    event2.destroy!
    assert airport.tags.where(name: :events).empty?, 'Events tag not removed from airport'
  end
end
