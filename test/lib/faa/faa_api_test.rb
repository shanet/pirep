require 'test_helper'
require 'faa/faa_api'

class FaaApiTest < ActiveSupport::TestCase
  setup do
    @client = FaaApi.client
  end

  test 'downloads airport data' do
    Dir.mktmpdir do |directory|
      files = @client.airport_data(directory)

      assert_requested :get, "https://nfdc.faa.gov/webContent/28DaySub/extra/#{@client.current_data_cycle(:airports).strftime('%d_%b_%Y')}_APT_CSV.zip"

      [:airports, :runways, :remarks].each do |type|
        assert files[type].present?, "Did not download #{type} data"
        assert File.exist?(files[type]), "Downloaded file for #{type} data does not exist"
      end
    end
  end

  test 'downloads airport diagrams' do
    Dir.mktmpdir do |directory|
      @client.airport_diagrams(directory)

      assert File.exist?(File.join(directory, '00142AD.PDF')), 'Did not download airport diagrams'
      assert File.exist?(File.join(directory, 'd-TPP_Metafile.xml')), 'Did not download airport diagram metadata file'
    end
  end

  test 'downloads all sectional charts' do
    assert_charts_downloaded(:sectional_charts)
    assert_charts_downloaded(:sectional_charts)
  end

  test 'downloads subset of sectional charts' do
    assert_charts_downloaded(:sectional_charts, charts_to_download: [:seattle, :salt_lake_city])
    assert_charts_downloaded(:sectional_charts, charts_to_download: [:seattle, :salt_lake_city])
  end

  test 'downloads terminal charts' do
    assert_charts_downloaded(:terminal_area_charts)
    assert_charts_downloaded(:terminal_area_charts)
  end

  test 'downloads test charts' do
    assert_charts_downloaded(:test_charts)
    assert_charts_downloaded(:test_charts)
  end

  test 'current data cycle' do
    # This method is memorized so we need to make new objects for each assertion
    travel_to(Date.new(2023, 6, 15)) do
      assert_equal Date.new(2023, 6, 15), FaaApi.client.current_data_cycle(:airports), 'Wrong airports data cycle'
      assert_equal Date.new(2023, 6, 15), FaaApi.client.current_data_cycle(:charts), 'Wrong charts data cycle'
      assert_equal Date.new(2023, 6, 15), FaaApi.client.current_data_cycle(:diagrams), 'Wrong diagrams data cycle'
    end

    # Only the airports and diagrams should change cycles in one month
    travel_to(Date.new(2023, 6, 15) + 1.month) do
      assert_equal Date.new(2023, 7, 13), FaaApi.client.current_data_cycle(:airports), 'Wrong airports data cycle'
      assert_equal Date.new(2023, 6, 15), FaaApi.client.current_data_cycle(:charts), 'Wrong charts data cycle'
      assert_equal Date.new(2023, 7, 13), FaaApi.client.current_data_cycle(:diagrams), 'Wrong diagrams data cycle'
    end

    # All products should change cycles in two months
    travel_to(Date.new(2023, 6, 15) + 2.months) do
      assert_equal Date.new(2023, 8, 10), FaaApi.client.current_data_cycle(:airports), 'Wrong airports data cycle'
      assert_equal Date.new(2023, 8, 10), FaaApi.client.current_data_cycle(:charts), 'Wrong charts data cycle'
      assert_equal Date.new(2023, 8, 10), FaaApi.client.current_data_cycle(:diagrams), 'Wrong diagrams data cycle'
    end

    # Just ensure that a past date won't cause an infinite loop or anything weird to happen
    travel_to(Date.new(1970, 1, 1)) do
      assert_equal Date.new(2020, 8, 13), FaaApi.client.current_data_cycle(:airports), 'Wrong airports data cycle'
    end
  end

private

  def assert_charts_downloaded(method, charts_to_download: nil)
    Dir.mktmpdir do |directory|
      @client.send(method, directory, charts_to_download)

      assert File.exist?(File.join(directory, 'Charts Test SEC.tif')), 'Did not extract chart TIFF'
      assert File.exist?(File.join(directory, 'Inset Test SEC.tif')), 'Did not extract inset chart TIFF'
    end
  end
end
