require 'test_helper'

class ChartsDownloaderTest < ActiveSupport::TestCase
  test 'creates tiles from geotiff' do
    output_directory = ChartsDownloader.new.download_and_convert(:test)

    # Assert that tiles were generated for each zoom level
    (0..11).each do |zoom_level| # rubocop:disable Style/EachForSimpleLoop
      assert File.exist?(File.join(output_directory, zoom_level.to_s)), "Missing tiles for zoom level #{zoom_level}"
    end
  end
end
