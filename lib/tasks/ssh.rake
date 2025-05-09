CLUSTER = 'pirep-production'

desc 'SSH to production'
task :ssh do # rubocop:disable Rails/RakeEnvironment
  session_manager_installed?

  containers = list_containers(CLUSTER)
  selected_container = choose_container(containers)
  open_session(CLUSTER, selected_container)
end

def list_containers(cluster)
  tasks = ecs_client.list_tasks(cluster: cluster)
  task_details = ecs_client.describe_tasks(cluster: cluster, tasks: tasks.task_arns)

  return task_details.tasks.map do |task|
    next unless task.last_status == 'RUNNING'

    task.containers.map do |container|
      {
        task_id: task.task_arn,
        container_name: container.name,
        ip_address: container.network_interfaces.first.private_ipv_4_address,
        runtime_id: container.runtime_id,
        started_at: task.started_at,
      }
    end
  end.flatten.compact
end

def choose_container(containers)
  options = containers.map do |container|
    "#{container[:container_name]}\tIP: #{container[:ip_address]}\tUptime: #{((Time.now - container[:started_at]) / 60).round(2)} minutes" # rubocop:disable Rails/TimeZone
  end

  if containers.empty?
    warn 'No running containers found'
    exit 1
  elsif containers.length == 1
    puts "Only one container running, using: #{options.first}"
    return containers.first
  end

  selected_ip_address = CLI::UI.ask('Select container:', options: options).split("\t")[1].gsub('IP: ', '')
  return containers.find {|container| container[:ip_address] == selected_ip_address}
end

def open_session(cluster, container)
  session = ecs_client.execute_command(cluster: cluster, task: container[:task_id], container: container[:container_name], interactive: true, command: '/bin/fish')

  Process.exec(
    'session-manager-plugin',
    {sessionId: session.session.session_id, streamUrl: session.session.stream_url, tokenValue: session.session.token_value}.to_json,
    'us-west-2',
    'StartSession',
    ENV['AWS_PROFILE'] || '',
    {Target: "ecs:#{cluster}_#{container[:task_id]}_#{container[:container_id]}"}.to_json,
    'https://ecs.us-west-2.amazonaws.com'
  )
end

def session_manager_installed?
  return true if system('which session-manager-plugin &> /dev/null')

  warn 'session-manager-plugin binary not found'
  exit 1
end

def ecs_client
  return $ecs ||= Aws::ECS::Client.new # rubocop:disable Style/GlobalVars
end
