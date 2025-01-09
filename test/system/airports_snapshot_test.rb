require 'application_system_test_case'

class AirportsSnapshotTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper

  setup do
    @airport = create(:airport)
    @airport.tags << create(:tag, :camping, airport: @airport)
    @airport.comments << create(:comment, airport: @airport)
    @airport.events << create(:event, airport: @airport)
    @airport.events << create(:event, :recurring, airport: @airport)
  end

  test 'gets snapshot of airport' do
    visit airport_path(@airport.code, format: :snapshot)

    # The snapshot page should be lacking certain elements
    assert_no_selector '.airport-subheader a'
    assert_no_selector '#upload-photo-form'
    assert_no_selector '#add-tag-form'
    assert_no_selector '#landing-rights-form'
    assert_no_selector '#add-webcam-form'
    assert_no_selector '#comments form'
    assert_no_selector 'footer'

    # Has a link to the live page
    assert find('a', text: 'View live page')

    # Has only one photo
    assert_selector '.carousel-item img', count: 1

    # Has only recurring events
    assert_selector '.event .list-group-item', count: 1
    assert_selector '.event .list-group-item h5', text: @airport.events.last.name

    # Has map and annotations
    assert_selector '#airport-map'
    assert_selector '.annotation', count: 2
    assert_no_selector '#annotations-editing'

    # Has comments without buttons
    assert_selector '#comments .comment', count: 1
    assert_no_selector '#comments .comment .comment-actions'
  end
end
