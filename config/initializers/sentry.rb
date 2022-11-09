if Rails.application.credentials.sentry_dsn_backend
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn_backend
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Tracing seems to have some issues with GoodJob. Disabling this for now, but it would be nice to try it out later for performance data.
    # Set traces_sample_rate to 1.0 to capture 100%
    # config.traces_sample_rate = 1.0
  end
end
