require 'test_helper'

class RackAttackCacheCleanerJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    RackAttackCacheCleanerJob.perform_now
    pass
  end
end
