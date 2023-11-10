require 'exceptions'
require_relative 'our_airports_api_stubs'

module OurAirportsApi
  def self.client
    if Rails.env.test?
      OurAirportsApiStubs.stub_requests
    end

    return Service.new
  end

  class Service
    def airport_data(destination_directory)
      return {
        airports: download_airport_data_archive(destination_directory, 'airports'),
        runways: download_airport_data_archive(destination_directory, 'runways'),
        regions: download_airport_data_archive(destination_directory, 'regions'),
      }
    end

  private

    def download_airport_data_archive(destination_directory, dataset)
      Rails.logger.info("Downloading OurAirports #{dataset} dataset")
      response = Faraday.get("https://davidmegginson.github.io/ourairports-data/#{dataset}.csv")
      raise Exceptions::AirportDatabaseDownloadFailed unless response.success?

      # Write the response to disk and return the path
      path = File.join(destination_directory, "our_airports_#{dataset}.csv")
      File.write(path, response.body)

      return path
    end
  end
end
