Rails.configuration.good_job = {
  enable_cron: true,
  max_threads: 2,
  on_thread_error: ->(error) {Sentry.capture_exception(error)},

  cron: {
    airport_events_tags_cleanup: {
      cron: '30 6 * * *', # Every day
      class: 'AirportEventsTagsCleanupJob',
    },

    airports_geojson_dump: {
      cron: '0 * * * *', # Every hour
      class: 'AirportGeojsonDumperJob',
    },

    content_packs_creator: {
      cron: '0 0 1 * *', # Every 1st of the month
      class: 'EcsTaskRunnerJob',
      args: 'pirep-production-content_packs',
    },

    events_importer_job: {
      cron: '0 7 * * *', # Every day
      class: 'EventsImporterJob',
    },

    # Maxmind update (https://support.maxmind.com/hc/en-us/articles/4408216129947-Download-and-Update-Databases)
    maxmind_database_update: {
      cron: '0 5 * * 3,6', # Midnight ET Wednesday & Saturday
      class: 'MaxmindDbUpdaterJob',
    },

    # Clean up the Rack::Attack cache periodically to keep it from accumlating throttle records
    rack_attack_cache_clean: {
      cron: '0 6 * * *', # Every day
      class: 'RackAttackCacheCleanerJob',
    },

    weather_report_update: {
      cron: '31 * * * *', # Every hour (right after most METARs are updated)
      class: 'WeatherReportUpdaterJob',
    },
  },
}
