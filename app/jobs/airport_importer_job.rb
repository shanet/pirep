class AirportImporterJob < ApplicationJob
  def perform
    airports = AirportDatabaseParser.new.download_and_parse
    AirportDatabaseImporter.new(airports).load_database

    AirportDiagramDownloader.new.download_and_convert

    [:sectional, :terminal, :caribbean].each do |chart_type|
      ChartsDownloader.new.download_and_convert(chart_type)
    end
  end
end
