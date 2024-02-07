require 'exceptions'
require_relative 'aviation_weather_api_stubs'

module AviationWeatherApi
  def self.client
    if Rails.env.local?
      AviationWeatherApiStubs.stub_requests
    end

    return Service.new
  end

  class Service
    def metars(destination_directory)
      gzip_path = download_aviation_weather_dataset(:metars, destination_directory)
      extracted_filename = 'metars.xml'
      extract_gzip(gzip_path, destination_directory, extracted_filename)

      return File.join(destination_directory, extracted_filename)
    end

    def tafs(destination_directory)
      gzip_path = download_aviation_weather_dataset(:tafs, destination_directory)
      extracted_filename = 'tafs.xml'
      extract_gzip(gzip_path, destination_directory, extracted_filename)

      return File.join(destination_directory, extracted_filename)
    end

  private

    def download_aviation_weather_dataset(dataset, destination_directory)
      Rails.logger.info("Downloading AviationWeather #{dataset} dataset")
      response = Faraday.get("https://aviationweather.gov/data/cache/#{dataset}.cache.xml.gz")
      raise Exceptions::AviationWeatherDownloadFailed unless response.success?

      # Write gzip file to disk
      gzip_path = File.join(destination_directory, "#{dataset}.xml.gz")
      File.binwrite(gzip_path, response.body)

      return gzip_path
    end

    def extract_gzip(gzip_path, destination_directory, destination_filename)
      Rails.logger.info("Extracting #{gzip_path} to #{File.join(destination_directory, destination_filename)}")

      Zlib::GzipReader.open(gzip_path) do |gzip|
        File.write(File.join(destination_directory, destination_filename), gzip.read)
      end
    end
  end
end
