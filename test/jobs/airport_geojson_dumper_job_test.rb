require 'test_helper'

class AirportGeojsonDumperJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    AirportGeojsonDumperJob.perform_now
    pass
  end
end
