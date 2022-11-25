require 'exceptions'
require 'zip'

module FaaApi
  def self.client
    return (Rails.env.test? ? Stub.new : Service.new)
  end

  module Base
    # There are five archive files to download from the FAA containing all airport diagrams and procedures
    # https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dtpp/
    AIRPORT_DIAGRAM_ARCHIVES = ['A', 'B', 'C', 'D', 'E']

    def airport_data(destination_directory)
      archive_path = download_airport_data_archive(destination_directory)
      extract_archive(destination_directory, archive_path)

      # Return the path to the extracted airport data file
      return {
        airports: File.join(destination_directory, 'APT_BASE.csv'),
        runways: File.join(destination_directory, 'APT_RWY.csv'),
        remarks: File.join(destination_directory, 'APT_RMK.csv'),
      }
    end

    def airport_diagrams(destination_directory)
      AIRPORT_DIAGRAM_ARCHIVES.each do |archive_index| # rubocop:disable Lint/UnreachableLoop
        archive_path = download_airport_diagram_archive(archive_index, destination_directory)
        extract_archive(destination_directory, archive_path)

        # Return the path to the metadata index
        return File.join(destination_directory, 'd-TPP_Metafile.xml')
      end
    end

    def charts(destination_directory, chart_type, charts_config, charts_to_download=nil)
      # Only download the given charts if specified
      charts_to_download = (charts_to_download ? charts_config.select {|key, _value| key.in?(Array(charts_to_download))} : charts_config)

      charts = {}

      charts_to_download.each do |key, chart|
        # Don't download any chart that is in an inset of another chart
        next if chart[:inset]

        chart_path = download_chart(chart[:archive], chart_type, destination_directory)
        extract_archive(destination_directory, chart_path)
        charts[key] = File.join(destination_directory, chart[:filename])

        # The Hawaii archive is special in that it includes charts for other islands as well so we have to handle those here
        chart&.[](:insets)&.each do |inset_key, inset_chart|
          charts[inset_key] = File.join(destination_directory, inset_chart)
        end
      end

      return charts
    end

    def extract_archive(destination_directory, archive_path)
      Rails.logger.info("Extracting #{archive_path} to #{destination_directory}")

      Zip::File.open(archive_path) do |archive|
        # Extract each file in the archive to the destination directory
        archive.each do |file|
          path = File.join(destination_directory, file.name)
          archive.extract(file, path)
        rescue Zip::DestinationFileExistsError
          # Ignore the file if it already exists, we must have already extracted it
        end
      end
    end

    def current_data_cycle
      # Objects of this class should not live longer than a data cycle so we can memoize this
      return @current_data_cycle if defined? @current_data_cycle

      # New data is available every 28 days
      # It may be worth updating the seed date periodically so we don't have to do as many iterations here
      cycle_length = 28.days
      next_cycle = Date.new(2020, 9, 10)

      # Iterate from the start cycle until we hit the current date than back up one cycle for the current one
      next_cycle += cycle_length while Date.current >= next_cycle

      @current_data_cycle = next_cycle - cycle_length
      return @current_data_cycle
    end

    def shapefile_path(chart_type, chart_name)
      return Rails.root.join("lib/faa/charts_crop_shapefiles/#{chart_type}/#{chart_name}.shp").to_s
    end
  end

  class Service
    include Base

    def download_airport_data_archive(destination_directory)
      response = Faraday.get("https://nfdc.faa.gov/webContent/28DaySub/extra/#{current_data_cycle.strftime('%d_%b_%Y')}_APT_CSV.zip")
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(destination_directory, 'archive.zip')
      File.binwrite(archive_path, response.body)

      return archive_path
    end

    def download_airport_diagram_archive(archive, destination_directory)
      response = Faraday.get("https://aeronav.faa.gov/upload_313-d/terminal/DDTPP#{archive}_#{current_data_cycle.strftime('%y%m%d')}.zip")
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(destination_directory, "archive_#{archive}.zip")
      File.binwrite(archive_path, response.body)

      return archive_path
    end

    def download_chart(chart, chart_type, destination_directory)
      Rails.logger.info("Downloading #{chart_type}/#{chart} chart")

      response = Faraday.get("https://aeronav.faa.gov/visual/#{current_data_cycle.strftime('%m-%d-%Y')}/#{chart_download_path(chart_type)}/#{chart}")
      raise Exceptions::ChartDownloadFailed unless response.success?

      # Write archive to disk
      chart_path = File.join(destination_directory, chart)
      File.binwrite(chart_path, response.body)

      return chart_path
    end

    def chart_download_path(chart_type)
      return {
        sectional: 'sectional-files',
        terminal: 'tac-files',
        caribbean: 'Caribbean',
      }[chart_type]
    end

    def sectional_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :sectional, Rails.configuration.sectional_charts, charts_to_download)
    end

    def terminal_area_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :terminal, Rails.configuration.terminal_area_charts, charts_to_download)
    end

    def caribbean_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :caribbean, Rails.configuration.caribbean_charts, charts_to_download)
    end

    def chart_shapefile(chart_type, chart_name)
      return shapefile_path(chart_type, chart_name)
    end
  end

  class Stub
    include Base

    def download_airport_data_archive(*)
      return Rails.root.join('test/fixtures/airport_data.zip')
    end

    def download_airport_diagram_archive(*)
      return Rails.root.join('test/fixtures/airport_diagrams.zip')
    end

    def download_chart(*)
      return Rails.root.join('test/fixtures/charts_test.zip')
    end

    def sectional_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :test, Rails.configuration.test_charts, charts_to_download)
    end

    def terminal_area_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :test, Rails.configuration.test_charts, charts_to_download)
    end

    def caribbean_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :test, Rails.configuration.test_charts, charts_to_download)
    end

    def test_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, :test, Rails.configuration.test_charts, charts_to_download)
    end

    def chart_shapefile(*)
      return shapefile_path('test', 'test')
    end
  end
end
