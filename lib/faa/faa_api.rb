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
      return File.join(destination_directory, 'APT.txt')
    end

    def airport_diagrams(destination_directory)
      AIRPORT_DIAGRAM_ARCHIVES.each do |archive_index| # rubocop:disable Lint/UnreachableLoop
        archive_path = download_airport_diagram_archive(archive_index, destination_directory)

        Zip::File.open(archive_path) do |archive|
          # Extract each file in the archive
          archive.each do |file|
            path = File.join(destination_directory, file.name)
            archive.extract(file, path)
          end
        end

        # Return the path to the metadata index
        return File.join(destination_directory, 'd-TPP_Metafile.xml')
      end
    end

    def extract_archive(destination_directory, archive_path)
      Zip::File.open(archive_path) do |archive|
        # Extract each file in the archive to the destination directory
        archive.each do |file|
          path = File.join(destination_directory, file.name)
          archive.extract(file, path)
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
  end

  class Service
    include Base

    def download_airport_data_archive(destination_directory)
      response = Faraday.get('https://nfdc.faa.gov/webContent/28DaySub/%s/APT.zip' % current_data_cycle.strftime('%Y-%m-%d'))
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(destination_directory, 'archive.zip')
      File.binwrite(archive_path, response.body)

      return archive_path
    end

    def download_airport_diagram_archive(archive, _destination_directory)
      response = Faraday.get('https://aeronav.faa.gov/upload_313-d/terminal/DDTPP%s_%s.zip' % [archive, current_data_cycle.strftime('%y%m%d')])
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write archive to disk
      archive_path = File.join(directory, 'archive_%s.zip' % archive)
      File.binwrite(archive_path, response.body)

      return archive_path
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
  end
end
