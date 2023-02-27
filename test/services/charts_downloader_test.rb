require 'test_helper'

class ChartsDownloaderTest < ActiveSupport::TestCase
  teardown do
    # Clean up the tiles directory
    FileUtils.rm_rf(Rails.public_path.join('assets/tiles_test/current/test'))
  end

  test 'creates tiles from geotiff' do
    ChartsDownloader.new.download_and_convert(:test)

    # Assert that tiles were generated for each zoom level
    (0..11).each do |zoom_level| # rubocop:disable Style/EachForSimpleLoop
      assert Rails.root.join("public/assets/tiles_test/current/test/#{zoom_level}").exist?, "Missing tiles for zoom level #{zoom_level}"
    end
  end
end
