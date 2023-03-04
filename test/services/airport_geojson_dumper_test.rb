require 'test_helper'

class AirportGeojsonDumperTest < ActiveSupport::TestCase
  setup do
    @dumper = AirportGeojsonDumper.new
  end

  test 'writes airports geojson to file' do
    @dumper.write_to_file

    path = AirportGeojsonDumper.cached
    assert File.exist?(File.join(Rails.public_path, path)), 'Airport GeoJSON not written to file' # rubocop:disable Rails/RootPathnameMethods

    # Creating a new airport should change the filename to ensure browser caches are busted
    create(:airport)
    @dumper.write_to_file
    assert_not_equal path, AirportGeojsonDumper.cached, 'Airport GeoJSON dump not updated with new airport'

    # There should only be one GeoJSON file written
    assert_equal 1, Dir.glob(File.join(File.dirname(File.join(Rails.public_path, path)), '**/*')).count, 'Airport GeoJSON files not cleaned up' # rubocop:disable Rails/RootPathnameMethods
  end

  test 'clears cache' do
    @dumper.write_to_file
    path = @dumper.class.cached

    @dumper.clear_cache!
    assert_not File.exist?(Rails.public_path.join(path).dirname), 'Airport GeoJSON cache not cleared'
  end
end
