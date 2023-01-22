require 'good_job'
require 'good_job/application_helper'

module GoodJob
  class ApplicationController < ActionController::Base
    # GoodJobs dashboard has its own assets that are not served through the CDN. Since this is an admin-only
    # page we can simply disable the CSP for it so the default CSP for the site does not block these assets
    content_security_policy false
  end
end
