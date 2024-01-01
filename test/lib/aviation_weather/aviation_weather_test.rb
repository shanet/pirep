require 'test_helper'
require 'aviation_weather/aviation_weather_api'

class AviationWeatherApiTest < ActiveSupport::TestCase
  setup do
    @client = AviationWeatherApi.client
  end

  test 'downloads METARs' do
    Dir.mktmpdir do |directory|
      @client.metars(directory)
      assert File.exist?(File.join(directory, 'metars.xml')), 'Did not download and decompress METARs'
    end
  end

  test 'downloads TAFs' do
    Dir.mktmpdir do |directory|
      @client.tafs(directory)
      assert File.exist?(File.join(directory, 'tafs.xml')), 'Did not download and decompress TAFs'
    end
  end
end
