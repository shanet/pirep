require 'test_helper'
require 'maxmind/maxmind_db'

class MaxmindDbTest < ActiveSupport::TestCase
  setup do
    @client = MaxmindDb.client
  end

  test 'downloads database and looks up IP' do
    @client.update_database!

    assert_requested :get, /https:\/\/download\.maxmind\.com\/app\/geoip_download\?edition_id=GeoLite2-City&license_key=.*&suffix=tar\.gz$/
    assert File.exist?(MaxmindDb::Service::DATABASE_PATH), 'Maxmind database not downloaded'

    # Doing a lookup after the database was downloaded should not result in a second download
    WebMock.reset!
    result = @client.geoip_lookup('127.0.0.1')

    assert_not_requested :get, /https:\/\/download\.maxmind\.com\/app\/geoip_download\?edition_id=GeoLite2-City&license_key=.*&suffix=tar\.gz$/

    assert result[:latitude].present?, 'Latitude not found for IP address'
    assert result[:longitude].present?, 'Longitude not found for IP address'
  end
end
