namespace :db do
  desc 'Backup database to S3'
  task backup: :environment do
    require 'exceptions'

    database_config = Rails.configuration.database_configuration[Rails.env]
    output = '/tmp/database.dump'

    command = [
      'pg_dump',
      '--host', database_config['host'],
      '--username', database_config['username'],
      '--dbname', database_config['database'],
      '--format', 'custom',
      '--file', output,
    ]

    puts 'Running pg_dump...'
    stdout_stderr, status = Open3.capture2e({'PGPASSWORD' => database_config['password']}, *command)

    unless status == 0
      puts "pg_dump execution failed:\n\n#{stdout_stderr}"
      raise Exceptions::DatabaseBackupFailed, "pg_dump exited with status #{status}"
    end

    s3_key = "#{database_config['database']}_database_backup_#{Time.zone.now.strftime('%Y_%m_%d')}.dump"

    puts 'Uploading database backup to S3...'
    response = Aws::S3::Client.new.put_object(
      body: File.open(output, 'r'),
      bucket: Rails.configuration.backups_bucket,
      content_type: 'application/octet-stream',
      key: s3_key
    )

    raise Exceptions::DatabaseBackupFailed, response.to_h unless response.etag

    puts "Database backed up to s3://#{Rails.configuration.backups_bucket}/#{s3_key}"
  end

  desc 'Download a database backup from S3'
  task download: :environment do
    CLI::UI::StdoutRouter.enable

    s3 = Aws::S3::Client.new
    bucket = 'pirep-production-backups'

    response = s3.list_objects_v2(bucket: bucket)

    # This is limited to 1,000 objects. There should never be this many backups though so no need to implement paging here.
    objects = response.contents.map do |object|
      next (object.key.end_with?('.dump') ? object.key : nil)
    end.compact.sort.reverse

    selected_object = CLI::UI::Prompt.ask('Database backup to download:', options: objects)

    CLI::UI::Spinner.spin("Downloading #{selected_object}...") do
      s3.get_object(bucket: bucket, key: selected_object, response_target: selected_object)
    end

    puts "Database backup downloaded to ./#{selected_object}"
  end
end

desc 'Sync S3 bucket'
task :s3_sync, [:destination] => :environment do |_task, argv|
  if argv[:destination].blank?
    puts 'Usage: rails s3_sync[path/to/destination]'
    next
  end

  system("aws s3 sync s3://pirep-production-assets/#{Airport::AIRPORT_PHOTOS_S3_PATH} #{argv[:destination]}")
end
