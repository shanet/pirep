require 'optparse'

PIPELINE_NAME = 'pirep-production'
ECS_CLUSTER_NAME = 'pirep-production'
DEFAULT_BRANCH = 'master'

# Usage: rails deploy -- --branch=BRANCH
desc 'Deploy to production'
task :deploy do # rubocop:disable Rails/RakeEnvironment
  options = parse_arguments
  update_branch(PIPELINE_NAME, options[:branch])

  execution_id = codepipeline_client.start_pipeline_execution(name: PIPELINE_NAME).pipeline_execution_id

  pipeline_stages(PIPELINE_NAME).each do |stage_name|
    # Don't continue checking stages if a stage failed
    unless monitor_stage(PIPELINE_NAME, stage_name, execution_id)
      log '{{red:Deployment failed}}'
      exit(1)
    end
  rescue Interrupt
    log '{{red:Interrupt caught, aborting deployment}}'
    abort_deployment!(PIPELINE_NAME, execution_id)
    exit 1
  end

  log 'Deployment complete'
end

def monitor_stage(pipeline_name, stage_name, execution_id) # rubocop:disable Naming/PredicateMethod
  stage_status = nil
  in_progress_statuses = ['InProgress', 'Stopping']

  loop do
    stage_status = pipeline_stage_status(pipeline_name, stage_name)

    # Wait until the stage's execution ID matches the current execution (it will report the previous pipeline run until it starts again)
    unless stage_status[:execution_id] == execution_id
      execution_status = pipeline_execution_status(pipeline_name, execution_id)

      # Stop waiting if the execution ended before reaching this stage (for example, it was superseded by another execution)
      unless in_progress_statuses.include?(execution_status)
        log "{{red:Pipeline execution #{execution_status.downcase} before reaching #{stage_name} stage}}"
        return false
      end

      log "Stage: #{stage_name}, Status: Waiting to start"
      next
    end

    # Show the rollout progress of each ECS service being deployed. Deploy actions are named after the service they deploy.
    # Failed rollouts are rolled back automatically by the ECS deployment circuit breaker.
    if stage_name == 'Deploy'
      stage_status[:action_states].each do |action|
        deployment = ecs_deployment(action[:name])
        action[:summary] = ecs_deployment_summary(deployment) if deployment
      end
    end

    puts_stage_status(stage_status)
    break unless in_progress_statuses.include?(stage_status[:status])
  ensure
    sleep 5
  end

  return stage_status[:status] == 'Succeeded'
end

def ecs_deployment(service_name)
  service = ecs_client.describe_services(cluster: ECS_CLUSTER_NAME, services: [service_name]).services.first
  return service&.deployments&.find {|deployment| deployment.status == 'PRIMARY'}
end

def ecs_deployment_summary(deployment)
  summary = "#{deployment.running_count}/#{deployment.desired_count} new tasks running"
  summary += ", #{deployment.rollout_state_reason}" if deployment.rollout_state == 'FAILED'
  return summary
end

def abort_deployment!(pipeline_name, codepipeline_execution_id)
  begin
    codepipeline_client.stop_pipeline_execution(pipeline_name: pipeline_name, pipeline_execution_id: codepipeline_execution_id, abandon: true, reason: 'Manual cancellation')
  rescue Aws::CodePipeline::Errors::PipelineExecutionNotStoppableException
    log 'Pipeline execution not found, skipping abort'
  end

  # Stopping the pipeline doesn't stop an ECS deployment that already started. That will either complete or be rolled back by the circuit breaker.
  log '{{yellow:Any ECS deployment that already started will continue}}'
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

    return {
      action_states: action_states,
      execution_id: stage.latest_execution&.pipeline_execution_id,
      name: stage.stage_name,
      status: stage.latest_execution&.status,
    }
  end

  return nil
end

def pipeline_execution_status(pipeline_name, execution_id)
  return codepipeline_client.get_pipeline_execution(pipeline_name: pipeline_name, pipeline_execution_id: execution_id).pipeline_execution.status
rescue Aws::CodePipeline::Errors::PipelineExecutionNotFoundException
  # A newly started execution may not be visible yet so treat it as in progress until it is
  return 'InProgress'
end

def puts_stage_status(stage_status)
  unless stage_status
    log 'Waiting for pipeline execution to begin'
    return
  end

  # Provide detailed info on each action if there are multiple. Otherwise the status of the overall status is sufficient.
  if stage_status[:action_states].many?
    actions_status = "\n\t" + stage_status[:action_states].map do |action| # rubocop:disable Style/StringConcatenation
      message = action[:name]
      message += ": #{action[:status]}" if action[:status]
      message += " (#{action[:summary]})" if action[:summary]
      next message
    end.join("\n\t")
  else
    actions_status = stage_status[:status]
    summary = stage_status[:action_states].first&.dig(:summary)
    actions_status += " (#{summary})" if summary
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

def ecs_client
  return $ecs ||= Aws::ECS::Client.new # rubocop:disable Style/GlobalVars
end

def parse_arguments
  options = {branch: DEFAULT_BRANCH}

  OptionParser.new do |parser|
    parser.on('-b', '--branch ARG', String) {|branch| options[:branch] = branch}
  end.parse!(ARGV.any? ? ARGV[1..] : ARGV)

  return options
end
