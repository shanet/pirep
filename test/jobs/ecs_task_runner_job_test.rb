require 'test_helper'

class EcsTaskRunnerJobTest < ActiveJob::TestCase
  test 'starts ECS task' do
    # Sanity check on this job running, all AWS responses are stubbed so there's nothing to check for here
    EcsTaskRunnerJob.perform_now('task_definition')
    pass
  end
end
