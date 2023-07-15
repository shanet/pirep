require 'test_helper'

class Manage::VersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport)
    sign_in :admin
  end

  test 'update airport version' do
    with_versioning do
      @airport.update!(description: 'making a version')

      patch manage_version_path(@airport.versions.last), params: {version: {reviewed_at: Time.zone.now}}
      assert_redirected_to history_airport_path(@airport)

      assert_in_delta Time.zone.now, @airport.versions.last.reviewed_at, 3.seconds, 'Version not set as reviewed'
    end
  end

  test 'update tag version' do
    with_versioning do
      tag = Tag.create!(name: :camping, airport: @airport)

      patch manage_version_path(tag.versions.last), params: {version: {reviewed_at: Time.zone.now}}
      assert_redirected_to history_airport_path(@airport)

      assert_in_delta Time.zone.now, tag.versions.last.reviewed_at, 3.seconds, 'Version not set as reviewed'
    end
  end
end
