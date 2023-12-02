WRITE_THROTTLED_PATHS = [
  /^\/airports.*\z/,
  /^\/comments\/.+\/flag\z/,
  /^\/comments\/.+\/helpful\z/,
  /^\/comments\/.+\/undo_outdated\z/,
  /^\/comments\z/,
  /^\/events\/.+\/edit\z/,
  /^\/events\/.+\z/,
  /^\/events\z/,
  /^\/tags\/.+\z/,
  /^\/user\/password\z/,
  /^\/user\/sign_in\z/,
  /^\/user\z/,
  /^\/webcams\z/,
]

READ_THROTTLED_PATHS = [
  /\/\z/,
  /\/airports\/.+\z/,
]

# If needed, specific IPs/subnets can be blocked by adding them here
BLACKLISTED_IPS = [
  '74.119.193.27', # Creating spam accounts
  '2a0a:6040:9731::a', # Creating spam accounts
  '45.134.26.52', # SQL injection attempts
]

Rails.configuration.rack_attack_write_limit = 10 # requests
Rails.configuration.rack_attack_read_limit = 240 # requests

# Throttle anyone making excessive changes to resources
Rack::Attack.throttle('limit excessive writes', limit: Rails.configuration.rack_attack_write_limit, period: 60) do |request|
  # Only throttle write requests
  next unless request.post? || request.put? || request.patch? || request.delete?

  request.ip if WRITE_THROTTLED_PATHS.any? {|path| path.match? request.path}
end

# Throttle anyone making excessive requests to main pages
Rack::Attack.throttle('limit excessive reads', limit: Rails.configuration.rack_attack_read_limit, period: 60) do |request|
  # Only throttle GET requests
  next unless request.get?

  request.ip if READ_THROTTLED_PATHS.any? {|path| path.match? request.path}
end

BLACKLISTED_IPS.each do |ip|
  Rack::Attack.blocklist_ip(ip)
end
