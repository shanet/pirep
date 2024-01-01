require 'test_helper'

class WeatherReportUpdaterJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    WeatherReportUpdaterJob.perform_now
    pass
  end
end
