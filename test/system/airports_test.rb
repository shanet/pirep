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

    # Has fuel info
    assert_selector '.statistics-box', text: "Fuel: #{@airport.fuel_types.join(', ')} (prices)"
    assert_selector ".statistics-box a[href=\"http://www.100ll.com/searchresults.php?searchfor=#{@airport.icao_code}\"]"

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

    # Wait for the uncached images to be fetched
    assert_selector('.carousel[data-uncached-photos-loaded="true"]')

    # Has photos with featured photo form
    expected_photo_path = URI.parse(url_for(@airport.contributed_photos.first)).path
    actual_photo_path = URI.parse(find('.carousel img')[:src]).path
    assert_equal expected_photo_path, actual_photo_path
    assert_selector '.carousel-item .featured'

    # Has airport map
    assert_selector '#airport-map'

    # Has airport diagram
    assert find('.airport-diagram img')[:src].present?

    # Has remarks
    assert_selector '.remark', text: @airport.remarks.first.text

    # Has comments
    assert_selector '.comment', text: @airport.comments.first.body
  end

  test 'add tag' do
    visit airport_path(@airport.code)

    # There should be three tags by default (two from the factory and the "edit tags" button)
    assert_equal 3, all('.tag-square').count

    # Add the first and last tag
    find('.tag-square.add').click
    tags = all('#add-tag-form .tag-square')
    tags.first.click
    tags.last.click

    click_button 'Add Tags'

    # There should now be four tags plus the "edit tags" button
    assert_equal 5, all('.tag-square').count, 'Tags not added'
  end

  test 'remove tag' do
    visit airport_path(@airport.code)

    # There should be three tags by default (two from the factory and the "edit tags" button)
    assert_equal 3, all('.tag-square').count

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

    click_button 'Edit Airport Access'
    find('#airport_landing_rights_restricted + label').click
    fill_in 'Requirements/contact info for landing:', with: contact
    click_button 'Update Airport Access'

    # Kind of messy, but check that the page has the expected landing rights text on it now
    landing_rights = find('.landing-rights').text
    assert landing_rights.include?(contact)
    assert landing_rights.include?(Airport::LANDING_RIGHTS_TYPES[:restricted][:long_description])
  end

  test 'edit textareas' do
    visit airport_path(@airport.code)

    # Check that we can update a field twice and the changes are not rejected as conflicting
    2.times do
      assert_editor_has_text('Description', :description, 'Description edit')
    end

    assert_editor_has_text('Transient Parking', :transient_parking, 'Transient parking edit')
    assert_editor_has_text('Fuel Location', :fuel_location, 'Fuel location edit')
    assert_editor_has_text('Landing & Tie-down Fees', :landing_fees, 'Landing fee edit')
    assert_editor_has_text('Crew Car Availability', :crew_car, 'Crew car edit')
    assert_editor_has_text('WiFi Access', :wifi, 'WiFi edit')

    # An update that would overwrite a conflicting change should be rejected
    with_versioning do
      travel_to(5.minutes.from_now) do
        @airport.update!(description: 'blerg')
      end

      travel_to(5.minutes.ago) do
        _editor, card = update_editor('Description', 'Description edit2')

        within(card) do
          assert_selector '.status-indicator.text-danger'
        end
      end
    end
  end

  test 'scrolls photos' do
    visit airport_path(@airport.code)

    # Wait for the uncached images to be fetched
    within('.carousel[data-uncached-photos-loaded="true"]') do
      images = all('.carousel-item', visible: false)
      previous_button = find('.carousel-control-prev')
      next_button = find('.carousel-control-next')

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

      # Clicking on an indicator should jump to that image
      all('.carousel-indicators button').last.click
      assert_image_shown images.last
    end
  end

  test 'fetches uncached photos' do
    # Add an external photo to act as something that was already cached
    @airport.external_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))
    @airport.update!(external_photos_updated_at: Time.zone.now)

    visit airport_path(@airport.code)

    # Wait for the uncached images to be fetched
    within('.carousel[data-uncached-photos-loaded="true"]') do
      images = all('img', visible: false)

      assert_equal 2, images.count, 'Wrong photos displayed by default'
      assert_equal url_for(@airport.contributed_photos.first), images.first[:src]
      assert_equal url_for(@airport.external_photos.first), images.last[:src]
    end

    # Removing the cache timestamp should now return uncached photos to display
    @airport.update!(external_photos_updated_at: nil)

    visit current_path

    # Wait for the uncached images to be fetched
    within('.carousel[data-uncached-photos-loaded="true"]') do
      images = all('img', visible: false)

      # The first photo should still be the contributed photo, the second and third should be direct links to the external photos
      assert_equal 3, images.count, 'Contributed photo not included with uncached external photos'
      assert_equal url_for(@airport.contributed_photos.first), images[0][:src]
      assert images[1][:src].end_with?('/images/placeholder_1.jpg')
      assert images[2][:src].end_with?('/images/placeholder_2.jpg')

      # Images with attributions should display it (these will currently on display on uncached photos)
      assert first('.carousel-caption', visible: false).text(:all).present?, 'Attribution not present for image'
    end
  end

  test 'upload photo' do
    visit airport_path(@airport.code)

    assert_difference -> {all('.carousel[data-uncached-photos-loaded="true"] img', visible: false).count} do
      click_button 'Add Photo'
      find('#upload-photo-form input[type="file"]').set(Rails.root.join('test/fixtures/files/image.png'))
      click_button 'Upload Photo'
    end
  end

  test 'set featured photo' do
    3.times {@airport.contributed_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))}

    visit airport_path(@airport.code)

    # Wait for the uncached images to be fetched
    assert_selector('.carousel[data-uncached-photos-loaded="true"]')

    # Go to the third image and set it as the featured image
    find('.carousel-indicators button[data-bs-target="2"]').click
    find('.carousel-item .featured').click

    assert_equal url_for(@airport.reload.featured_photo), find('.carousel-item img')[:src], 'Unexpected featured photo'
    assert_equal 'Featured Photo', find('.carousel-item .featured.disable').text, 'First photo not set as featured with disabled button'
  end

  test 'has webcams' do
    webcam1 = create(:webcam, airport: @airport, url: 'https://example.com')
    webcam2 = create(:webcam, airport: @airport, url: 'https://subdomain.example.com')

    visit airport_path(@airport.code)

    assert_selector "a.webcam-link[href=\"#{webcam1.url}\"]"
    assert_selector "a.webcam-link[href=\"#{webcam2.url}\"]"
  end

  test 'add webcam' do
    visit airport_path(@airport.code)
    click_button 'Add Webcam'

    url = 'example.com/image.jpg'
    find_by_id('webcam_url').fill_in with: url
    find('input[type="submit"][value="Add Webcam"]').click

    assert_selector "img.webcam-image[src=\"https://#{url}\"]"
  end

  test 'leave a comment' do
    visit airport_path(@airport.code)
    comment = 'I am a comment'

    find_by_id('comment_body').fill_in with: comment
    click_button 'Add Comment'

    assert_equal comment, all('.comment p').last.text, 'New comment not on page'
  end

  test 'helpful comment' do
    visit airport_path(@airport.code)
    click_button 'Helpful'
    assert_selector '.helpful-count'
  end

  test 'flag comment as outdated' do
    visit airport_path(@airport.code)
    click_button 'Flag as outdated'
    assert_selector '.alert.outdated-at'
  end

  test 'changes cover image' do
    visit airport_path(@airport.code)

    click_button 'Theme'
    click_link 'Forest'

    assert_selector '.airport-header-cover-image.cover-image-forest'
    assert_equal 'forest', @airport.reload.cover_image, 'Cover image not updated on airport'
  end

  test 'has meta and opengraph tags' do
    visit airport_path(@airport.code)

    # Sanity check on the meta tags being present
    assert_equal "#{@airport.code} - #{@airport.name.titleize} Airport", find('meta[name="title"]', visible: false)[:content], 'Unexpected meta name'
    assert_equal @airport.description, find('meta[name="description"]', visible: false)[:content], 'Unexpected meta description'
    assert_equal @airport.description, find('meta[property="og:description"]', visible: false)[:content], 'Unexpected Opengraph description'
  end

private

  def assert_editor_has_text(label, property, text)
    editor, card = update_editor(label, text)

    # Check that the editor has the given text in read mode and that the backend was updated accordingly
    within(editor) do
      assert_equal text, find('.editor-preview-full').text, 'Editor value not saved after clicking off of editor'
    end

    # Check that the status indicator is shown and also wait for the update request to complete before checking if the value was persisted to the backend below
    within(card) do
      assert_selector '.status-indicator.text-success'
    end

    assert_equal text, @airport.reload.send(property), 'Editor value not updated on backend'
  end

  def update_editor(label, text)
    editor = nil
    card = find('.card', text: label)

    # Find the editor with the given label
    within(card) do
      # Click on the editor to enter edit mode
      editor = find('.EasyMDEContainer')
      editor.click

      within(editor) do
        assert editor[:class].include?('editing'), 'Editor not in edit mode'

        # Select all the text currently in the editor, delete it, and then enter the given text
        find('div[contenteditable="true"]', visible: false).send_keys([(/darwin/ =~ RUBY_PLATFORM ? :meta : :control), 'a'], :backspace, text)
      end
    end

    # Click off of the editor to write changes and exit edit mode
    find('.airport-header').click

    return editor, card
  end

  def assert_image_shown(image)
    assert image[:class].include?('active')
  end
end
