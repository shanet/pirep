require 'test_helper'

class FetchAirportTimezoneJobTest < ActiveJob::TestCase
  setup do
    @airport = create(:airport, timezone: nil, timezone_checked_at: nil)
  end

  test 'updates timezone' do
    FetchAirportTimezoneJob.perform_now(@airport)
    assert_not_nil @airport.reload.timezone, 'Timezone not set'
    assert_not_nil @airport.reload.timezone_checked_at, 'Timezone checked at timestamp not set'
  end
end
