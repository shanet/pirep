require 'maxmind/maxmind_db'

class Pageview < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :user, class_name: Users::User.name.to_s

  USER_AGENT_PARSER = UserAgentParser::Parser.new

  # Consider anything else a spider. This will likely miss some real users, but I'd rather
  # have a slight undercount here from someone using an uncommon browser than a large
  # overcount by ingesting spider traffic as pageviews.
  WHITELISTED_BROWSERS = Set.new([
                                   'Chrome Mobile WebView',
                                   'Chrome Mobile',
                                   'Chrome',
                                   'Edge',
                                   'Firefox Mobile',
                                   'Firefox',
                                   'IE',
                                   'Mobile Safari',
                                   'Opera',
                                   'Safari',
                                 ])

  def self.spider?(user_agent)
    parsed_user_agent = USER_AGENT_PARSER.parse(user_agent)

    return WHITELISTED_BROWSERS.exclude?(parsed_user_agent.family)
  end

  def user_agent=(user_agent)
    self[:user_agent] = user_agent

    parsed_user_agent = USER_AGENT_PARSER.parse(user_agent)

    self[:operating_system] = parsed_user_agent.os&.family
    self[:browser] = parsed_user_agent.family
    self[:browser_version] = parsed_user_agent.version&.major
  end

  def ip_address=(ip_address)
    self[:ip_address] = ip_address

    geoip = MaxmindDb.client.geoip_lookup(ip_address)
    return unless geoip

    self[:latitude] = geoip[:latitude]
    self[:longitude] = geoip[:longitude]
  end
end
