require 'test_helper'
require 'our_airports/our_airports_api'

class OurAirportsApiTest < ActiveSupport::TestCase
  setup do
    @client = OurAirportsApi.client
  end

  test 'downloads airport data' do
    Dir.mktmpdir do |directory|
      files = @client.airport_data(directory)

      assert_requested :get, 'https://davidmegginson.github.io/ourairports-data/airports.csv'

      [:airports, :runways, :regions].each do |type|
        assert files[type].present?, "Did not download #{type} data"
        assert File.exist?(files[type]), "Downloaded file for #{type} data does not exist"
      end
    end
  end
end
