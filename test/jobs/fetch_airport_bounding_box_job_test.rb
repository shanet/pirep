require 'test_helper'

class FetchAirportBoundingBoxJobTest < ActiveJob::TestCase
  setup do
    @airport = create(:airport, :no_bounding_box)
  end

  test 'updates bounding box' do
    FetchAirportBoundingBoxJob.perform_now(@airport)
    assert @airport.reload.has_bounding_box?, 'Bounding box not set'
  end
end
