class AirportImporterJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    airports = AirportDatabaseParser.new.download_and_parse
    AirportDatabaseImporter.new(airports).load_database

    AirportDiagramDownloader.new.download_and_convert
  end
end
