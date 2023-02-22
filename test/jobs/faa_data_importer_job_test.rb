require 'test_helper'

class FaaDataImporterJobTest < ActiveJob::TestCase
  test 'starts importer task' do
    # Sanity check on this job running, all AWS responses are stubbed so there's nothing to check for here
    FaaDataImporterJob.perform_now
    pass
  end
end
