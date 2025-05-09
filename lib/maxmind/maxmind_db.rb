require 'exceptions'
require_relative 'maxmind_db_stubs'

module MaxmindDb
  def self.client
    unless Rails.application.credentials.maxmind_license_key
      MaxmindDbStubs.stub_requests
    end

    return Service.new
  end

  class Service
    DATABASE_PATH = File.join(Rails.configuration.try(:efs_path).presence || Rails.root, "lib/maxmind/geolite2_city_#{Rails.env}.mmdb") # rubocop:disable Rails/FilePath, Rails/SafeNavigation
    DATABASE_URL = "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=#{Rails.application.credentials.maxmind_license_key}&suffix=tar.gz"

    def geoip_lookup(ip_address)
      result = maxmind_database.city(ip_address)
      return {latitude: result.location.latitude, longitude: result.location.longitude, country: result.registered_country.iso_code}
    rescue MaxMind::GeoIP2::AddressNotFoundError
      return nil
    rescue => error
      # Don't be silent during tests
      raise error if Rails.env.test?

      # Any errors with the geoip lookup should be captured, but not cause the caller to experience an exception
      Sentry.capture_exception(error)
      return nil
    end

    def update_database!
      Rails.logger.info('Updating Maxmind database')

      Dir.mktmpdir do |directory|
        database = File.open(File.join(directory, 'database.tar.gz'), 'wb')
        checksum = File.open(File.join(directory, 'database.tar.gz.sha256'), 'w')

        response = faraday_get_follow_redirects(DATABASE_URL)
        raise Exceptions::MaxmindDatabaseDownloadFailed unless response.success?

        database.write(response.body)

        # Download the database checuksum and replace the filename in the checksum with the one we wrote above (since by default it has a date string in the filename)
        response = faraday_get_follow_redirects("#{DATABASE_URL}.sha256")
        raise Exceptions::MaxmindDatabaseChecksumDownloadFailed unless response.success?

        checksum.write(response.body.gsub(/  .+.tar.gz/, "  #{database.path}"))

        database.close
        checksum.close

        raise Exceptions::MaxmindDatabaseIntegrityCheckFailed unless system("cat #{checksum.path} | sha256sum -c - > /dev/null")

        # Extract database and move it to a new directory since the default one has a date string in the name
        system("tar -xf #{database.path} --directory #{directory} && mv #{directory}/GeoLite2-City_* #{directory}/database")

        # Swap out the old database with the new one and reset/re-initialize the database reader object
        FileUtils.mkdir_p(File.dirname(DATABASE_PATH))
        FileUtils.cp(File.join(directory, 'database/GeoLite2-City.mmdb'), DATABASE_PATH)

        @maxmind_database = nil
      end

      Rails.logger.info('Updated Maxmind database')
    end

  private

    def maxmind_database
      update_database! unless File.exist?(DATABASE_PATH)

      @maxmind_database ||= if Rails.env.test?
                              MaxmindDbStubs::StubDatabaseReader.new
                            else
                              MaxMind::GeoIP2::Reader.new(database: DATABASE_PATH.to_s)
                            end
    end

    # Maxmind will redirect database downloads to a cloud provider storage URL so we need to follow redirects
    # This is more minimal than adding another Faraday middleware gem. Maybe this should be moved to a monkeypatch?
    def faraday_get_follow_redirects(url)
      response = Faraday.get(url)

      if response.status.in?([301, 302]) && response.headers['Location']
        return faraday_get_follow_redirects(response.headers['Location'])
      end

      return response
    end
  end
end
