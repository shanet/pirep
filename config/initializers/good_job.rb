Rails.configuration.good_job = {
  enable_cron: true,
  cron: {
    airports_geojson_dump: {
      cron: '0 * * * *', # Every hour
      class: 'AirportGeojsonDumperJob',
    },

    # Maxmind update (https://support.maxmind.com/hc/en-us/articles/4408216129947-Download-and-Update-Databases)
    maxmind_database_update: {
      cron: '0 5 * * 3,6', # Midnight ET Wednesday & Saturday
      class: 'MaxmindDbUpdaterJob',
    },
  },
}
