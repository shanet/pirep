class AirportImporterJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    airports = AirportDatabaseParser.new.download_and_parse
    AirportImporter.new(airports).load_database
  end
end
