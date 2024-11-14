require 'application_system_test_case'

class Manage::DashboardTest < ApplicationSystemTestCase
  setup do
    # Create some actions to fill the dashboard with
    @comment = create(:comment)
    @user = create(:known)

    @airport = create(:airport, :unmapped).reload
    @airport.update!(description: 'foobar')
    @airport.tags << Tag.new(name: :golfing)
    @airport.destroy!
  end

  test 'marks revision in queue as reviewed' do
    sign_in :admin
    visit manage_root_path

    # Apporving a record from the review queue should remove it from the queue
    find(".review-record[data-record-id=\"#{@comment.id}\"] form button").click
    assert_no_selector ".review-record[data-record-id=\"#{@comment.id}\"]"
  end

  test 'has revisions in queue' do
    with_versioning do
      # Create a new webcam as an unknown user
      airport = create(:airport)
      visit airport_path(airport.code)
      click_link_or_button 'Add Webcam'

      find_by_id('webcam_url').fill_in with: 'example.com/image.jpg'
      find('input[type="submit"][value="Add Webcam"]').click

      # Ensure that it is now in the dashboard review queue
      sign_in :admin
      visit manage_root_path

      assert_selector ".review-record[data-record-id=\"#{Webcam.last.versions.last.id}\"]"
    end
  end

  test 'switches color schemes' do
    sign_in :admin
    visit manage_root_path

    # Open the color scheme menu and assert that "auto" is selected by default
    find('.color-scheme-selector').click
    assert_selector '#color-scheme-options .dropdown-item[data-color-scheme="auto"]', visible: false

    # Switch to dark mode and verify that the active item was set to "dark" and that the top level data attribute is set
    find('#color-scheme-options .dropdown-item[data-color-scheme="dark"]').click
    assert_selector '#color-scheme-options .dropdown-item.active[data-color-scheme="dark"]', visible: false
    assert_selector 'body[data-bs-theme="dark"]'

    # Open the menu again and switch to light mode
    find('.color-scheme-selector').click
    find('#color-scheme-options .dropdown-item[data-color-scheme="light"]').click
    assert_selector '#color-scheme-options .dropdown-item.active[data-color-scheme="light"]', visible: false
    assert_no_selector 'body[data-bs-theme="dark"]'
  end
end
