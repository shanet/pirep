require 'test_helper'

class MasterDataImporterJobTest < ActiveJob::TestCase
  test 'starts importer task' do
    # Sanity check on this job running, all AWS responses are stubbed so there's nothing to check for here
    MasterDataImporterJob.perform_now
    pass
  end
end
