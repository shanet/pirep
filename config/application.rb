require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module Pirep
  class Application < Rails::Application
    # Always show Ruby deprecation warnings
    Warning[:deprecated] = true

    config.load_defaults 8.0

    # Add db/ to the load path for classes the seeds use that live in there
    $LOAD_PATH << Rails.root.join('db')

    config.domain = 'pirep.io'
    config.active_job.queue_adapter = :good_job
    config.pagination_page_size = 50

    config.supported_timezones = [ActiveSupport::TimeZone.new('Etc/UTC')] + ActiveSupport::TimeZone.us_zones

    config.meta_title = 'Pirep - Collaborative Airport Database'
    config.meta_description = 'Pirep is a free, collaborative database of all public and private airports located within the United States.'

    config.asset_bucket = ENV['RAILS_ASSET_BUCKET'] || 'stub-bucket'
    config.backups_bucket = ENV['RAILS_BACKUPS_BUCKET'] || 'stub-bucket'

    # Override the default form error HTML with something compatible with Bootstrap
    config.action_view.field_error_proc = proc do |html_tag, _instance|
      html_tag.gsub('form-control', 'form-control is-invalid').html_safe
    end
  end
end
