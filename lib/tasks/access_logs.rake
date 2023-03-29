LOGS_PATH = 's3://pirep-production-logs/load_balancer/AWSLogs/176997720438/elasticloadbalancing/us-west-2'

desc 'Generate access log reports'
task :access_logs do # rubocop:disable Rails/RakeEnvironment
  destination = Rails.root.join('log/access_logs')

  unless download_logs(destination)
    puts 'Failed to download access logs from S3'
    exit 1
  end

  analyze_logs(destination)
end

def download_logs(destination)
  return system("aws s3 sync #{LOGS_PATH} #{destination}")
end

def analyze_logs(logs_directory)
  Dir.glob("#{logs_directory}/**/*.log.gz") do |log|
    puts "Decompressing #{log}"
    `gunzip --force #{log}`
  end

  logs = Dir.glob("#{logs_directory}/**/*.log")

  puts 'Generating report'
  output = 'access_logs.html'

  `goaccess \
    --agent-list \
    --ignore-crawlers \
    --enable-panel GEO_LOCATION \
    --geoip-database #{Rails.root.join('lib/maxmind/geolite2_city.mmdb')} \
    --log-format AWSALB \
    #{logs.join(' ')} \
    > #{output} \
  `

  puts "#{'=' * 80}\nReport written to #{output}"
  `xdg-open access_logs.html`
end
