require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module Pirep
  class Application < Rails::Application
    config.load_defaults 7.0

    config.pagination_page_size = 50
  end
end
