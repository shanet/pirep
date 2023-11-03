require 'application_system_test_case'

class EventsTest < ApplicationSystemTestCase
  setup do
    @event = create(:event)
  end

  test 'edits event' do
    visit edit_event_path(@event)

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
