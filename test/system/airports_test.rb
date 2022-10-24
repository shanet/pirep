require 'application_system_test_case'

class AirportsTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper

  setup do
    @airport = create(:airport)
    @airport.tags << create(:tag, :camping, airport: @airport)
    @airport.comments << create(:comment, airport: @airport)
  end

  test 'visit airport show page' do
    visit airport_path(@airport.code)

    # Has header
    assert_selector '.airport-header', text: "#{@airport.code} - #{@airport.name.titleize}"

    # Has tags
    assert_selector '.tag-square', text: Tag::TAGS[@airport.tags.first.name][:label]

    # Has elevation
    assert_selector '.statistics-box', text: "Elevation: #{number_with_delimiter(@airport.elevation, delimiter: ',')}ft"

    # Has runway info
    @airport.runways.each do |runway|
      assert_selector '.statistics-box', text: "Runway #{runway.number}: #{number_with_delimiter(runway.length, delimiter: ',')}ft"
    end

    # Has landing rights
    assert_selector '.landing-rights', text: Airport::LANDING_RIGHTS_TYPES[@airport.landing_rights][:long_description]

    # Has textareas
    [
      @airport.description,
      @airport.transient_parking,
      @airport.fuel_location,
      @airport.landing_fees,
      @airport.crew_car,
      @airport.wifi,
    ].each do |text|
      assert_selector '.EasyMDEContainer', text: text
    end

    # Has photos
    expected_photo_path = URI.parse(url_for(@airport.photos.first)).path
    actual_photo_path = URI.parse(find('.photo-gallery img')[:src]).path
    assert_equal expected_photo_path, actual_photo_path

    # Has airport diagram
    assert find('.airport-diagram img')[:src].present?

    # Has remarks
    assert_selector '.remark', text: @airport.remarks.first.text

    # Has comments
    assert_selector '.comment', text: @airport.comments.first.body
  end

  test 'add tag' do
    visit airport_path(@airport.code)

    # There should be two tags by default (one from factory and "edit tags" button)
    assert_equal 2, all('.tag-square').count

    # Add the first and last tag
    find('.tag-square.add').click
    tags = all('#add-tag-form .tag-square')
    tags.first.click
    tags.last.click

    click_on 'Add Tags'

    # There should now be three tags plus the "edit tags" button
    assert_equal 4, all('.tag-square').count, 'Tags not added'
  end

  test 'remove tag' do
    visit airport_path(@airport.code)

    # There should be two tags by default (one from factory and "edit tags" button)
    assert_equal 2, all('.tag-square').count

    # Remove the first tag
    find('.tag-square.add').click
    find('.tag-square .delete').click

    assert_no_selector '.tag-square .delete'
  end

  test 'cannot remove non-addable tag' do
    @airport.tags.each(&:destroy!)
    create(:tag, name: :private_, airport: @airport)
    visit airport_path(@airport.code)

    # There should be two tags by default (one from factory and "edit tags" button)
    assert_equal 2, all('.tag-square').count

    # Remove the first tag
    find('.tag-square.add').click

    assert_no_selector '.tag-square .delete'
  end

  test 'edit airport access' do
    visit airport_path(@airport.code)
    contact = 'Call 867-5309 for info'

    click_on 'Edit Airport Access'
    find('.landing-rights-box[data-landing-rights-type="restrictions"]').click
    fill_in 'Requirements for landing:', with: contact
    click_on 'Update Airport Access'

    # Kind of messy, but check that the page has the expected landing rights text on it now
    landing_rights = find('.landing-rights').text
    assert landing_rights.include?(contact)
    assert landing_rights.include?(Airport::LANDING_RIGHTS_TYPES[:restrictions][:long_description])
  end

  test 'edit textareas' do
    visit airport_path(@airport.code)

    assert_editor_has_text('Description', :description, 'Description edit')
    assert_editor_has_text('Transient Parking', :transient_parking, 'Transient parking edit')
    assert_editor_has_text('Fuel Location', :fuel_location, 'Fuel location edit')
    assert_editor_has_text('Landing & Tie-down Fees', :landing_fees, 'Landing fee edit')
    assert_editor_has_text('Crew Car Availability', :crew_car, 'Crew car edit')
    assert_editor_has_text('WiFi Access', :wifi, 'WiFi edit')
  end

  test 'scrolls photos' do
    visit airport_path(@airport.code)

    within('.photo-gallery') do
      images = all('img', visible: false)
      previous_button = find('.previous')
      next_button = find('.next')

      # The first image should be shown by default
      assert_image_shown images.first

      # Go to the second image
      next_button.click
      assert_image_shown images[1]

      # Back to the first
      previous_button.click
      assert_image_shown images.first

      # Going back again should wrap around to the last image
      previous_button.click
      assert_image_shown images.last

      # Going forward from the end should wrap around to the first image
      next_button.click
      assert_image_shown images.first
    end
  end

  test 'upload photo' do
    visit airport_path(@airport.code)

    assert_difference -> {all('.photo-gallery img', visible: false).count} do
      click_on 'Add Photo'
      find('#upload-photo-form input[type="file"]').set(Rails.root.join('test/fixtures/files/image.png'))
      click_on 'Upload Photo'
    end
  end

  test 'leave a comment' do
    visit airport_path(@airport.code)
    comment = 'I am a comment'

    find('#comment_body').fill_in with: comment
    click_on 'Add Comment'

    assert_equal comment, all('.comment p').last.text, 'New comment not on page'
  end

  test 'helpful comment' do
    visit airport_path(@airport.code)
    click_on 'Helpful'
    assert_selector '.helpful-count'
  end

  test 'flag comment as outdated' do
    visit airport_path(@airport.code)
    click_on 'Flag as outdated'
    assert_selector '.alert.outdated-at'
  end

private

  def assert_editor_has_text(label, property, text)
    editor = nil

    # Find the editor with the given label
    within(find('.card', text: label)) do
      # Click on the editor to enter edit mode
      editor = find('.EasyMDEContainer')
      editor.click

      within(editor) do
        assert editor[:class].include?('editing'), 'Editor not in edit mode'

        # Select all the text currently in the editor, delete it, and then enter the given text
        find('textarea', visible: false).send_keys([:control, 'a'], [:meta, 'a'], :backspace, text)
      end
    end

    # Click off of the editor to write changes and exit edit mode
    find('.airport-header').click

    # Check that the editor has the given text in read mode and that the backend was updated accordingly
    within(editor) do
      assert_equal text, find('.editor-preview-full').text, 'Editor value not saved after clicking off of editor'
      assert_equal text, @airport.reload.send(property), 'Editor value not updated on backend'
    end
  end

  def assert_image_shown(image)
    assert image[:class].include?('active')
  end
end
