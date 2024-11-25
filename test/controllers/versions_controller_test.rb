require 'test_helper'

class VersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @airport = create(:airport)

    sign_in create(:admin)
  end

  test 'revert airport edit' do
    with_versioning do
      original_description = @airport.description
      @airport.update! description: 'Changed'

      # Revert the update made above
      patch revert_version_path(@airport.versions.last)
      assert_redirected_to airport_path(@airport)

      assert_equal original_description, @airport.reload.description, 'Airport not reverted to previous version'
    end
  end

  test 'revert tags' do
    airport = create(:airport, :empty)

    with_versioning do
      airport.tags << create(:tag, airport: airport)
      airport.save!

      assert_equal 2, airport.tags.count, 'Airport has no tags'

      # Revert the tag creation and expect the airport to have no tags
      assert_difference('airport.tags.count', -1) do
        patch revert_version_path(airport.tags.last.versions.last)
        assert_redirected_to airport_path(airport)
      end

      # Revert the revert and expect the airport to have a tag again
      assert_difference('airport.tags.count') do
        patch revert_version_path(airport.tags.last.versions.last)
        assert_redirected_to airport_path(airport)
      end
    end
  end

  test 'revert webcam deletion' do
    with_versioning do
      webcam = create(:webcam)
      webcam.destroy!

      patch revert_version_path(webcam.versions.last)

      assert_redirected_to airport_path(webcam.airport)
      assert Webcam.find(webcam.id), 'Deleted webcam not restored'
    end
  end

  test 'revert already reverted version' do
    with_versioning do
      @airport.update!(transient_parking: 'over there')
      version = @airport.versions.last

      patch revert_version_path(version)
      assert_redirected_to airport_path(@airport)

      # Reverting a reverted version should be rejected
      patch revert_version_path(version)
      assert_response :bad_request
    end
  end
end
