require 'test_helper'

class AirportPhotosCacherJobTest < ActiveJob::TestCase
  setup do
    @airport = create(:airport)

    @photos = [
      {url: ActionController::Base.helpers.asset_url('logo.png')},
      {url: ActionController::Base.helpers.asset_url('logo.png')},
    ]
  end

  test 'caches photos' do
    AirportPhotosCacherJob.perform_now(@airport, @photos)

    assert_not_nil @airport.external_photos_updated_at, 'Cached updated timestamp not set'
    assert_equal 2, @airport.external_photos.count, 'Photos not attached to airport'
  end

  test 'saves attributions and photo references as metadata' do
    photos_with_metadata = [
      {url: ActionController::Base.helpers.asset_url('logo.png'), attribution: 'Photo by Jane Doe', google_photo_reference: 'ref123'},
      {url: ActionController::Base.helpers.asset_url('logo.png'), attribution: 'Attribution 1, Attribution 2', google_photo_reference: 'ref456'},
      {url: ActionController::Base.helpers.asset_url('logo.png')},
    ]

    AirportPhotosCacherJob.perform_now(@airport, photos_with_metadata)

    assert_equal 3, @airport.external_photos.count, 'Photos not attached to airport'

    assert_equal 'Photo by Jane Doe', @airport.external_photos[0].metadata['attribution'], 'First photo attribution not saved'
    assert_equal 'ref123', @airport.external_photos[0].metadata['google_photo_reference'], 'First photo reference not saved'

    assert_equal 'Attribution 1, Attribution 2', @airport.external_photos[1].metadata['attribution'], 'Second photo attribution not saved'
    assert_equal 'ref456', @airport.external_photos[1].metadata['google_photo_reference'], 'Second photo reference not saved'

    assert_nil @airport.external_photos[2].metadata['attribution'], 'Third photo should not have attribution'
    assert_nil @airport.external_photos[2].metadata['google_photo_reference'], 'Third photo should not have photo reference'
  end
end
