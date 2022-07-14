require 'test_helper'

class AirportImporterJobTest < ActiveJob::TestCase
  test 'imports airports' do
    assert_difference('Airport.count', 1) do
      AirportImporterJob.new.perform
    end
  end
end
