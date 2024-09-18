require 'ostruct'

module MaxmindDbStubs
  def self.stub_requests
    WebMock.stub_request(:get, /https:\/\/download\.maxmind\.com\/app\/geoip_download\?edition_id=GeoLite2-City&license_key=.*&suffix=tar\.gz$/)
      .to_return(body: Rails.root.join('test/fixtures/maxmind/geolite2_city_stub.tar.gz').read)

    WebMock.stub_request(:get, /https:\/\/download\.maxmind\.com\/app\/geoip_download\?edition_id=GeoLite2-City&license_key=.*&suffix=tar\.gz\.sha256$/)
      .to_return(body: "#{Digest::SHA256.hexdigest(Rails.root.join('test/fixtures/maxmind/geolite2_city_stub.tar.gz').read)}  geolite2_city_stub.tar.gz")

    WebMock.enable!
  end

  class StubDatabaseReader
    def city(_ip_address)
      # rubocop:disable Style/OpenStructUse
      return OpenStruct.new(
        location: OpenStruct.new(latitude: 47.62055376532627, longitude: -122.34936256185215),
        registered_country: OpenStruct.new(iso_code: 'US')
      )
      # rubocop:enable Style/OpenStructUse
    end
  end
end
