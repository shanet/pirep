require 'test_helper'

class EventsImporterJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    EventsImporterJob.perform_now
    pass
  end
end
