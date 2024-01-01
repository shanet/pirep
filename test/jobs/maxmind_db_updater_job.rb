require 'test_helper'

class MaxmindDbUpdaterJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    MaxmindDbUpdaterJob.perform_now
    pass
  end
end
