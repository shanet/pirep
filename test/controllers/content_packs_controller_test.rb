require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    get content_packs_path
    assert_response :success
  end

  test 'show' do
    # Write a dummy content pack to the expected directory
    FileUtils.mkdir_p(ContentPacksCreator.directory)
    test_contents = 'content pack contents'
    File.write(File.join(ContentPacksCreator.directory, "pirep_camping_#{Time.zone.now}.zip"), test_contents)

    get content_pack_path(:camping)
    assert_equal test_contents, response.body, 'Did not send content pack archive'
  end

  test 'show with invalid content pack' do
    get content_pack_path(:invalid)
    assert_response :not_found
  end
end
