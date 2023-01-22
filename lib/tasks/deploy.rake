require 'optparse'

PIPELINE_NAME = 'pirep-production'
DEPLOYMENT_APPLICATION_NAME = 'pirep-production'
DEFAULT_BRANCH = 'master'

$codedeploy_deployments = {} # rubocop:disable Style/GlobalVars

# Usage: rails deploy -- --branch=BRANCH
desc 'Deploy to production'
task :deploy do # rubocop:disable Rails/RakeEnvironment
  options = parse_arguments
  update_branch(PIPELINE_NAME, options[:branch])

  execution_id = codepipeline_client.start_pipeline_execution(name: PIPELINE_NAME).pipeline_execution_id

  pipeline_stages(PIPELINE_NAME).each do |stage_name|
    # Don't continue checking stages if a stage failed
    unless monitor_stage(PIPELINE_NAME, stage_name)
      log '{{red:Deployment failed}}'
      exit(1)
    end
  rescue Interrupt
    log '{{red:Interrupt caught, aborting deployment}}'
    abort_deployment!(PIPELINE_NAME, execution_id, $codedeploy_deployments) # rubocop:disable Style/GlobalVars
    exit 1
  end

  log 'Deployment complete'
end

def monitor_stage(pipeline_name, stage_name)
  stage_status = nil
  rollback_prompted = false
  continue_statuses = ['InProgress', 'Stopped', 'Failed']

  loop do
    stage_status = pipeline_stage_status(pipeline_name, stage_name)

    # Do more detailed monitoring of the deploy stage
    if stage_name == 'Deploy'
      deployment_groups = stage_status[:action_states].pluck(:name)
      codedeploy_status = monitor_codedeploy(deployment_groups)
      $codedeploy_deployments = codedeploy_status[:deployments] # rubocop:disable Style/GlobalVars

      # Update the action state summary with more detailed info from the codedeploy status
      stage_status[:action_states].each do |deployment_group|
        next unless codedeploy_status[:deployments][deployment_group[:name]][:waiting_for_termination]

        deployment_group[:summary] = 'Waiting for original task set termination'
      end

      # Ask to rollback if a codedeploy group failed
      if codedeploy_status[:status] == :failed && !rollback_prompted
        log '{{red:Deployment failed}}'
        rollback!(codedeploy_status[:deployments])

        # Only prompt for a rollback once
        rollback_prompted = true
      end
    end

    puts_stage_status(stage_status)

    # We may be picking up the status from the previous deploy so only break on non-in-progress statuses after we've seen an in-progress status at least once
    if stage_status[:status] == 'InProgress'
      continue_statuses = ['InProgress']
    end

    break unless continue_statuses.include?(stage_status[:status])
  ensure
    sleep 5
  end

  return (stage_status[:status] == 'Succeeded')
end

def monitor_codedeploy(deployment_groups)
  response = codedeploy_client.batch_get_deployment_groups(application_name: DEPLOYMENT_APPLICATION_NAME, deployment_group_names: deployment_groups)

  failed = false
  deployments = {}

  response.deployment_groups_info.each do |deployment_group|
    deployment_id = deployment_group.last_attempted_deployment.deployment_id
    deployment_status = deployment_group.last_attempted_deployment.status
    waiting_for_termination = codedeploy_client.get_deployment(deployment_id: deployment_id).deployment_info.instance_termination_wait_time_started

    deployments[deployment_group.deployment_group_name] = {
      deployment_id: deployment_id,
      waiting_for_termination: waiting_for_termination,
    }

    failed = true if ['Failed', 'Stopped'].include?(deployment_status)
  end

  return {status: (failed ? :failed : :in_progress), deployments: deployments}
end

def rollback!(deployments)
  answer = CLI::UI.ask('Rollback all services?', options: ['Yes', 'No'])
  return unless answer == 'Yes'

  deployments.each do |_deployment_group, deployment_info|
    response = codedeploy_client.stop_deployment(deployment_id: deployment_info[:deployment_id], auto_rollback_enabled: true)
    log("Rollback status for deployment #{deployment_info[:deployment_id]}: #{response.status}")
  end
end

def abort_deployment!(pipeline_name, codepipeline_execution_id, codedeploy_deployments)
  begin
    codepipeline_client.stop_pipeline_execution(pipeline_name: pipeline_name, pipeline_execution_id: codepipeline_execution_id, abandon: true, reason: 'Manual cancellation')
  rescue Aws::CodePipeline::Errors::PipelineExecutionNotStoppableException
    log 'Pipeline execution not found, skipping abort'
  end

  codedeploy_deployments.each do |_deployment_group, deployment_info|
    codedeploy_client.stop_deployment(deployment_id: deployment_info[:deployment_id], auto_rollback_enabled: false)
  end
end

def pipeline_stage_status(pipeline_name, stage_name)
  response = codepipeline_client.get_pipeline_state(name: pipeline_name)

  response.stage_states.each do |stage|
    next unless stage.stage_name == stage_name

    action_states = stage.action_states.map do |action|
      {
        name: action.action_name,
        status: action.latest_execution&.status,
        summary: action.latest_execution&.summary,
      }
    end

    return {name: stage.stage_name, status: stage.latest_execution.status, action_states: action_states}
  end

  return nil
end

def puts_stage_status(stage_status)
  unless stage_status
    log 'Waiting for pipeline execution to begin'
    return
  end

  # Provide detailed info on each action if there are multiple. Otherwise the status of the overall status is sufficient.
  if stage_status[:action_states].count > 1
    actions_status = "\n\t" + stage_status[:action_states].map do |action| # rubocop:disable Style/StringConcatenation
      message = action[:name]
      message += ": #{action[:status]}" if action[:status]
      message += " (#{action[:summary]})" if action[:summary]
      next message
    end.join("\n\t")
  else
    actions_status = stage_status[:status]
  end

  log "Stage: #{stage_status[:name]}, Status: #{actions_status}"
end

def log(message)
  puts CLI::UI.fmt("{{blue:#{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}:}} #{message}") # rubocop:disable Rails/TimeZone
end

def update_branch(pipeline_name, branch)
  response = codepipeline_client.get_pipeline(name: pipeline_name)
  source_action = find_source_action(response.pipeline)

  if source_action.configuration['BranchName'] == branch
    log 'Branch is up to date'
    return
  end

  log "Updating branch to {{red:#{branch}}}"
  source_action.configuration['BranchName'] = branch
  response = codepipeline_client.update_pipeline(pipeline: response.pipeline)

  # Ensure that the branch was updated as expected
  if find_source_action(response.pipeline).configuration['BranchName'] != branch # rubocop:disable Style/GuardClause
    log '{{red:Failed to update branch name}}'
    exit 1
  end
end

def find_source_action(pipeline)
  pipeline.stages.each do |stage|
    stage.actions.each do |action|
      return action if action.action_type_id.category == 'Source'
    end
  end
end

def pipeline_stages(pipeline_name)
  response = codepipeline_client.get_pipeline(name: pipeline_name)
  return response.pipeline.stages.pluck(:name)
end

def codepipeline_client
  return $codepipeline ||= Aws::CodePipeline::Client.new # rubocop:disable Style/GlobalVars
end

def codedeploy_client
  return $codedeploy ||= Aws::CodeDeploy::Client.new # rubocop:disable Style/GlobalVars
end

def parse_arguments
  options = {branch: DEFAULT_BRANCH}

  OptionParser.new do |parser|
    parser.on('-b', '--branch ARG', String) {|branch| options[:branch] = branch}
  end.parse!(ARGV[1..])

  return options
end
