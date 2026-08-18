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

  test 'saves attributions as metadata' do
    photos_with_attribution = [
      {url: ActionController::Base.helpers.asset_url('logo.png'), attribution: 'Photo by Jane Doe'},
      {url: ActionController::Base.helpers.asset_url('logo.png'), attribution: 'Attribution 1, Attribution 2'},
      {url: ActionController::Base.helpers.asset_url('logo.png')},
    ]

    AirportPhotosCacherJob.perform_now(@airport, photos_with_attribution)

    assert_equal 3, @airport.external_photos.count, 'Photos not attached to airport'
    assert_equal 'Photo by Jane Doe', @airport.external_photos[0].metadata['attribution'], 'First photo attribution not saved'
    assert_equal 'Attribution 1, Attribution 2', @airport.external_photos[1].metadata['attribution'], 'Second photo attribution not saved'
    assert_nil @airport.external_photos[2].metadata['attribution'], 'Third photo should not have attribution'
  end
end
