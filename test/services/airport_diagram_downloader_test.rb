require 'test_helper'

class AirportDiagramDownloaderTest < ActiveSupport::TestCase
  setup do
    # The airport code has to match what's in the airport diagrams zip fixture
    @airport = create(:airport, code: 'PAE')
  end

  test 'parses airport diagram archive from FAA' do
    AirportDiagramDownloader.new.download_and_convert
    assert_equal '00142AD.png', @airport.diagram, 'Airport diagram not set'
  end
end
