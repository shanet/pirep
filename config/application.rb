require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module Pirep
  class Application < Rails::Application
    config.load_defaults 7.0

    config.pagination_page_size = 50

    # Override the default form error HTML with something compatible with Bootstrap
    config.action_view.field_error_proc = proc do |html_tag, _instance|
      html_tag.gsub('form-control', 'form-control is-invalid').html_safe
    end
  end
end
