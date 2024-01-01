require 'test_helper'

class VersionsCollatorJobTest < ActiveJob::TestCase
  test 'performs job' do
    # Sanity check on the job running without errors. The service class itself is tested elsewhere.
    VersionsCollatorJob.perform_now(create(:airport))
    pass
  end
end
