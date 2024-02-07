require 'application_system_test_case'

class Manage::PaginationTest < ApplicationSystemTestCase
  setup do
    # Lower the pagiantion size to minimize the number of records we have to create here
    @original_page_size = Rails.configuration.pagination_page_size
    Rails.configuration.pagination_page_size = 10
  end

  teardown do
    Rails.configuration.pagination_page_size = @original_page_size
  end

  test 'paginates index with many records' do
    sign_in :admin

    num_pages = 6
    ((Rails.configuration.pagination_page_size * num_pages) - Users::User.count).times {create(:known)}

    visit manage_users_path

    # There should be the correct number of records in the table
    assert_selector 'table tbody tr', count: Rails.configuration.pagination_page_size

    # There should be a total of 7 page links, 5 for the individual page links and then two for the "first" and "last" links
    assert_selector '.pagination .page-item', count: 7

    # The "first" link should be disabled
    assert_selector '.pagination .page-item:first-child .page-link.disabled'

    # The first page link should be active
    assert_selector '.pagination .page-item:nth-child(2) .page-link.active'

    within('.pagination') do
      click_link_or_button '2'
    end

    # The second page link should now be active
    assert_selector '.pagination .page-item:nth-child(3) .page-link.active'

    # The "first" link should be active now
    assert_selector '.pagination .page-item:first-child .page-link'

    within('.pagination') do
      click_link_or_button '3'
    end

    # The third page link should now be active
    assert_selector '.pagination .page-item:nth-child(4) .page-link.active'

    within('.pagination') do
      click_link_or_button '4'
    end

    # The third page link should still be active as there are more than five pages and this is the center
    assert_selector '.pagination .page-item:nth-child(4) .page-link.active'

    within('.pagination') do
      click_link_or_button '5'
    end

    # The fourth page link should still be active as there are less than three pages left before the last page
    assert_selector '.pagination .page-item:nth-child(5) .page-link.active'

    within('.pagination') do
      click_link_or_button 'Last'
    end

    # The last page link should be active now
    assert_selector '.pagination .page-item:nth-child(6) .page-link.active'

    # The "last" link should be disabled
    assert_selector '.pagination .page-item:last-child .page-link.disabled'
  end

  test 'paginates index with few records' do
    sign_in :admin

    num_pages = 1
    ((Rails.configuration.pagination_page_size * num_pages) - Users::User.count).times {create(:known)}

    visit manage_users_path

    # There should be a total of 3 page links, 1 for the individual page links and then two for the "first" and "last" links
    assert_selector '.pagination .page-item', count: 3
  end
end
