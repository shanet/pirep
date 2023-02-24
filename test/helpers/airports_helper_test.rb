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

  test 'diffs strings and arrays' do
    assert diff('foo', 'bar').left, 'Handled diff of strings'
    assert diff([{label: 'foo', latitude: 0, longitude: 0}], [{label: 'bar', latitude: 0, longitude: 0}]).left, 'Handled diff of annotations'
  end

  test 'opengraph description' do
    airport = create(:airport)
    assert_equal airport.description, opengraph_description(airport), 'Did not use airport description'

    airport.update!(description: "1\n2\n3")
    assert_equal "1\n2", opengraph_description(airport), 'Used more than two lines from description'

    airport.update!(description: nil)
    assert opengraph_description(airport).start_with?(airport.name.titleize)

    airport.tags << create(:tag, name: :unmapped)
    assert 'unmapped'.in?(opengraph_description(airport)), 'Unmapped language not used for unmapped airport'
  end

  test 'opengraph image' do
    airport = create(:airport, contributed_photos: nil)

    # Use the site icon if there are no photos for the airport
    assert_equal image_url('icon_small.png'), opengraph_image(airport), 'Did not use site icon'

    # Use external photos next
    airport.external_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))
    assert_equal cdn_url_for(airport.external_photos.first), opengraph_image(airport), 'Did not use external photo first'

    # Then contributed photos
    airport.contributed_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))
    assert_equal cdn_url_for(airport.contributed_photos.first), opengraph_image(airport), 'Did not use contributed photo first'

    # Finally, prefer a featured photo
    airport.update!(featured_photo: airport.contributed_photos.first)
    assert_equal cdn_url_for(airport.featured_photo), opengraph_image(airport), 'Did not use featured photo first'
  end
end
