require 'application_system_test_case'

class EventsTest < ApplicationSystemTestCase
  setup do
    @event = create(:event, :recurring)
  end

  test 'edits event' do
    visit edit_event_path(@event)

    # There should be two week-of-month options for the 4th/5th day in a month
    fill_in 'event_start_date', with: DateTime.new(2023, 7, 22)
    assert_equal ['day_22', 'week_4', 'week_-1'], all('#event_recurring_week_of_month > option').map(&:value)
    fill_in 'event_start_date', with: DateTime.new(2023, 7, 29)
    assert_equal ['day_29', 'week_5', 'week_-1'], all('#event_recurring_week_of_month > option').map(&:value)

    fill_in 'Description', with: 'Lorem ipsum'
    click_button 'Submit'

    assert find_by_id('events').text.include?('Lorem ipsum'), 'Event not edited'
  end

  test 'destroys event' do
    visit edit_event_path(@event)

    assert_difference('Event.count', -1) do
      accept_alert do
        click_button 'Delete'
      end

      page.assert_text('No upcoming events.')
    end
  end
end
