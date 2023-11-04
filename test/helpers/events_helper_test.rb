require 'test_helper'

class EventsHelperTest < ActionView::TestCase
  include EventsHelper

  test 'week_of_month_default_option' do
    assert_nil week_of_month_default_option(create(:event)), 'Incorrect default week of month option for static event'

    assert_equal 'day_13', week_of_month_default_option(create(:event, :recurring, recurring_day_of_month: 13, recurring_week_of_month: nil)),
                 'Incorrect default week of month option for recurring event'

    assert_equal 'week_3', week_of_month_default_option(create(:event, :recurring, recurring_day_of_month: nil, recurring_week_of_month: 3)),
                 'Incorrect default week of month option for recurring event'
  end
end
