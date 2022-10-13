require 'test_helper'

class AirportsHelperTest < ActionView::TestCase
  include AirportsHelper

  test 'version author' do
    unknown = create(:unknown)
    known = create(:known)

    with_versioning do
      version = create(:airport).versions.first

      # A nil whodunnit should return a default string
      assert_equal 'System', version_author(version)

      version.update!(whodunnit: unknown.id)
      assert manage_user_path(unknown).in?(version_author(version))

      version.update!(whodunnit: known.id)
      assert manage_user_path(known).in?(version_author(version))
    end
  end

  test 'static image for bounding box airport' do
    airport = create(:airport)
    bounding_box = [airport.bbox_sw_longitude, airport.bbox_sw_latitude, airport.bbox_ne_longitude, airport.bbox_ne_latitude].join(',')

    url = airport_satellite_image(airport)
    assert bounding_box.in?(url), 'Bounding box for airport not in satellite image URL'
  end

  test 'static image for non-bounding box airport' do
    airport = create(:airport, :no_bounding_box)
    url = airport_satellite_image(airport)
    assert [airport.longitude, airport.latitude, 16].join(',').in?(url), 'Center coordinates/zoom level for airport not in satellite image URL'
  end

  test 'static image for heliport' do
    airport = create(:airport, facility_type: 'heliport')
    url = airport_satellite_image(airport)
    assert [airport.longitude, airport.latitude, 17].join(',').in?(url), 'Center coordinates/zoom level for heliport not in satellite image URL'
  end
end
