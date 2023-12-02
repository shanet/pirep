require 'exceptions'

class MasterDataImporterJob < ApplicationJob
  ECS_CLUSTER = 'pirep-production'
  ECS_SERVICE_JOBS = 'pirep-production-jobs'
  ECS_SERVICE_IMPORTER = 'pirep-production-importer'

  def perform
    network_configuration = find_network_configuration(ECS_CLUSTER, ECS_SERVICE_JOBS)
    raise Exceptions::MasterDataImporterTaskFailed, 'ECS service network configuration not found' unless network_configuration

    task_definition = find_task_definition(ECS_SERVICE_IMPORTER)
    raise Exceptions::MasterDataImporterTaskFailed, 'ECS task definition not found' unless task_definition

    Rails.logger.info("Using task definition: #{task_definition}")

    task_arn = run_task(ECS_CLUSTER, task_definition, network_configuration)
    raise Exceptions::MasterDataImporterTaskFailed, 'Failed to run task' unless task_arn

    Rails.logger.info("Importer task started: #{task_arn}")
  end

private

  def find_network_configuration(cluster, service)
    response = ecs.describe_services(cluster: cluster, services: [service])
    network_configuration = response&.services&.first&.network_configuration

    # Stub this in test
    network_configuration ||= {} if Rails.env.test?

    return network_configuration
  end

  def find_task_definition(service)
    response = ecs.list_task_definitions(family_prefix: service, sort: 'DESC')
    task_definition = response.task_definition_arns.first

    # Stub this in test
    task_definition ||= '' if Rails.env.test?

    return task_definition
  end

  def run_task(cluster, task_definition, network_configuration)
    response = ecs.run_task(cluster: cluster, enable_execute_command: true, launch_type: 'FARGATE', task_definition: task_definition, network_configuration: network_configuration)
    task_arn = response&.tasks&.first&.containers&.first&.task_arn

    # Stub this in test
    task_arn ||= '' if Rails.env.test?

    return task_arn
  end

  def ecs
    @ecs_client ||= Aws::ECS::Client.new
    return @ecs_client
  end
end
