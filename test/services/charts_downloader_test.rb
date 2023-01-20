require 'test_helper'

class ChartsDownloaderTest < ActiveSupport::TestCase
  setup do
    # Create a `current` directory to ensure that the tiles generation code handles its existance properly
    FileUtils.mkdir_p(Rails.public_path.join('assets/tiles_test/test/current'))
  end

  teardown do
    # Clean up the tiles directory
    FileUtils.rm_rf(Rails.public_path.join('assets/tiles_test/test'))
  end

  test 'creates tiles from geotiff' do
    ChartsDownloader.new.download_and_convert(:test)

    # Assert that tiles were generated for each zoom level
    (0..11).each do |zoom_level| # rubocop:disable Style/EachForSimpleLoop
      assert Rails.root.join("public/assets/tiles_test/test/current/#{zoom_level}").exist?, "Missing tiles for zoom level #{zoom_level}"
    end
  end
end
