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
end
