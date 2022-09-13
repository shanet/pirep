require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  test 'destroy' do
    delete tag_path(id: create(:tag), format: :js)
    assert_response :success
  end

  test 'revert' do
    sign_in create(:admin)

    with_versioning do
      airport = create(:airport)
      tag = create(:tag, airport: airport)

      assert_equal 1, airport.tags.count, 'Airport has no tags'

      # Revert the tag creation and expect the airport to have no tags
      assert_difference('airport.tags.count', -1) do
        patch revert_tag_path(tag.versions.last.id)
        assert_redirected_to airport_path(airport)
      end

      # Revert the revert and expect the airport to have a tag again
      assert_difference('airport.tags.count') do
        patch revert_tag_path(tag.versions.last.id)
        assert_redirected_to airport_path(airport)
      end
    end
  end
end
