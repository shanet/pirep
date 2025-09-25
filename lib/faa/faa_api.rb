require 'exceptions'
require 'zip'
require_relative 'faa_api_stubs'

module FaaApi
  def self.client
    if Rails.env.test?
      FaaApiStubs.stub_requests
    end

    return Service.new
  end

  class Service
    # There are five archive files to download from the FAA containing all airport diagrams and procedures
    # https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dtpp/
    AIRPORT_DIAGRAM_ARCHIVES = ['A', 'B', 'C', 'D', 'E']

    CACHE_DIRECTORY = '.faa_cache'

    # New data is available every 28 or 56 days depending on the product
    CYCLE_LENGTHS = {
      airports: 28.days,
      charts: 56.days,
      diagrams: 28.days,
    }

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
      AIRPORT_DIAGRAM_ARCHIVES.each do |archive_index|
        archive_path = download_airport_diagram_archive(archive_index, destination_directory)
        extract_archive(destination_directory, archive_path)
      end

      # Return the path to the metadata index
      return File.join(destination_directory, 'd-TPP_Metafile.xml')
    end

    def sectional_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, Rails.configuration.sectional_charts, charts_to_download)
    end

    def terminal_area_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, Rails.configuration.terminal_area_charts, charts_to_download)
    end

    def test_charts(destination_directory, charts_to_download=nil)
      return charts(destination_directory, Rails.configuration.test_charts, charts_to_download)
    end

    def charts(destination_directory, charts_config, charts_to_download=nil)
      # Only download the given charts if specified (ensure these are pulled out in the same order as they are defined)
      if charts_to_download
        charts_to_download = Array(charts_to_download).map(&:to_sym)
        charts_to_download = charts_config.slice(*charts_to_download)
      else
        charts_to_download = charts_config
      end

      charts = {}

      charts_to_download.each do |key, chart|
        # Don't download any chart that is in an inset of another chart
        next if chart[:inset]

        chart_path = download_chart(chart[:archive], chart[:type], destination_directory)
        extract_archive(destination_directory, chart_path)
        charts[key] = File.join(destination_directory, chart[:filename])

        # The Hawaii archive is special in that it includes charts for other islands as well so we have to handle those here
        chart&.[](:insets)&.each do |inset_key, inset_chart|
          charts[inset_key] = File.join(destination_directory, inset_chart)
        end
      end

      return charts
    end

    def chart_shapefile(chart_type, chart_name)
      # In test we should always return a special test fixture
      if Rails.env.test?
        chart_type = 'test'
        chart_name = 'test'
      end

      return Rails.root.join("lib/faa/charts_crop_shapefiles/#{chart_type}/#{chart_name}.shp").to_s
    end

    def current_data_cycle(product)
      # Objects of this class should not live longer than a data cycle so we can memoize this
      return @current_data_cycle[product] if defined?(@current_data_cycle) && @current_data_cycle&.[](product)

      raise Exceptions::UnknownFaaProductType unless CYCLE_LENGTHS[product]

      # It may be worth updating the seed date periodically so we don't have to do as many iterations here
      next_cycle = Date.new(2020, 9, 10)

      # Iterate from the start cycle until we hit the current date than back up one cycle for the current one
      next_cycle += CYCLE_LENGTHS[product] while Date.current >= next_cycle

      @current_data_cycle ||= {}
      @current_data_cycle[product] = next_cycle - CYCLE_LENGTHS[product]

      return @current_data_cycle[product]
    end

  private

    def download_airport_data_archive(destination_directory)
      Rails.logger.info('Downloading FAA airports archive')
      response = Faraday.get("https://nfdc.faa.gov/webContent/28DaySub/extra/#{current_data_cycle(:airports).strftime('%d_%b_%Y')}_APT_CSV.zip")
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(destination_directory, 'archive.zip')
      File.binwrite(archive_path, response.body)

      return archive_path
    end

    def download_airport_diagram_archive(archive, destination_directory)
      output_filename = "archive_#{archive}.zip"

      # Try to use a cache if running in development so we don't need to download these large files multiple times
      unless Rails.env.production?
        cached_diagrams = cached_archive(:diagrams, output_filename)
        return cached_diagrams if cached_diagrams
      end

      Rails.logger.info("Downloading diagram archive \"#{archive}\"")
      response = Faraday.get("https://aeronav.faa.gov/upload_313-d/terminal/DDTPP#{archive}_#{current_data_cycle(:diagrams).strftime('%y%m%d')}.zip")
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(destination_directory, output_filename)
      File.binwrite(archive_path, response.body)

      # Write the archive to the development cache
      cache_archive(:diagrams, "archive_#{archive}.zip", response.body) unless Rails.env.production?

      return archive_path
    end

    def download_chart(chart, chart_type, destination_directory)
      Rails.logger.info("Downloading #{chart_type}/#{chart} chart archive")

      # Try to use a cache if running in development so we don't need to download these large files multiple times
      unless Rails.env.production?
        cached_chart = cached_archive(:charts, "#{chart_type}/#{chart}")
        return cached_chart if cached_chart
      end

      charts_cycle = current_data_cycle(:charts).strftime('%m-%d-%Y')

      response = Faraday.get("https://aeronav.faa.gov/visual/#{charts_cycle}/#{chart_download_path(chart_type)}/#{chart}")
      raise Exceptions::ChartDownloadFailed(response.body) unless response.success?

      # Write archive to disk
      chart_path = File.join(destination_directory, chart)
      File.binwrite(chart_path, response.body)

      # Write the chart to the development cache
      cache_archive(:charts, "#{chart_type}/#{chart}", response.body) unless Rails.env.production?

      return chart_path
    end

    def cached_archive(product, filename)
      cached_archive = cache_directory(product).join(filename)

      if File.exist?(cached_archive)
        Rails.logger.info("Using cached archive, delete #{cache_directory(product)} to bust cache")
        return cached_archive
      end

      return nil
    end

    def cache_archive(product, filename, file)
      FileUtils.mkdir_p(cache_directory(product).join(File.dirname(filename)).to_s)
      File.binwrite(cache_directory(product).join(filename).to_s, file)
    end

    def cache_directory(product)
      return Rails.root.join(CACHE_DIRECTORY, Rails.env, product.to_s)
    end

    def chart_download_path(chart_type)
      return {
        sectional: 'sectional-files',
        terminal: 'tac-files',
        caribbean: 'Caribbean',
        test: 'test',
      }[chart_type]
    end

    def extract_archive(destination_directory, archive_path)
      Rails.logger.info("Extracting #{archive_path} to #{destination_directory}")

      Zip::File.open(archive_path) do |archive|
        # Extract each file in the archive to the destination directory
        archive.each do |file|
          archive.extract(file, destination_directory: destination_directory)
        rescue Zip::DestinationExistsError
          # Ignore the file if it already exists, we must have already extracted it
        end
      end
    end
  end
end
