require 'application_system_test_case'

class AirportsAdvancedSearchTest < ApplicationSystemTestCase
  setup do
    @airport1 = create(:airport)
    @airport2 = create(:airport)
  end

  test 'searches airports' do
    visit advanced_search_airports_path

    click_link_or_button 'Location'
    fill_in 'distance_miles', with: '10'
    fill_in 'airport_from', with: @airport2.code

    find('input[type="submit"]').click

    assert_equal 'Search results: 2', find('.advanced-search span.rounded-pill').text, 'Wrong search result count'
    assert_equal 2, all('.results .result').count, 'Wrong number of search results'

    assert 'show-instant'.in?(find_by_id('filter-group-location')[:class].split), 'Location filter group not open after search'
    assert_equal '10', find_by_id('distance_miles').value, 'Distance from filter not still populated after search'
    assert_equal @airport2.code, find_by_id('airport_from').value, 'Airport from filter not still populated after search'
  end

  test 'sets filter group header badge counts' do
    visit advanced_search_airports_path

    click_link_or_button 'Location'
    fill_in 'distance_miles', with: '10'
    all('h1').first.click # Remove focus from the input
    assert_filter_group_count 1, 'filter-group-location'

    # Entering a value for another input in an input group should not increment the count
    fill_in 'airport_from', with: @airport2.code
    all('h1').first.click # Remove focus from the input
    assert_filter_group_count 1, 'filter-group-location'

    # The count should be decremented only when all inputs in the input group are empty
    fill_in 'distance_miles', with: ''
    assert_filter_group_count 1, 'filter-group-location'
    fill_in 'airport_from', with: ''
    assert_filter_group_count 0, 'filter-group-location'

    click_link_or_button 'Tags'

    # Meta-inputs should not affect the count
    find('label[for="tags_match_and"]').click
    assert_filter_group_count 0, 'filter-group-tags'

    # Selecting/deselecting a tag should update the count
    find('.tag-square[data-tag-name="unmapped"]').click
    assert_filter_group_count 1, 'filter-group-tags'

    find('.tag-square[data-tag-name="unmapped"]').click
    assert_filter_group_count 0, 'filter-group-tags'
  end

  test 'sets filter parameters in URL' do
    visit advanced_search_airports_path
    click_link_or_button 'Access'

    find('label[for="access_public"]').click
    assert 'access_public=1'.in?(URI.parse(current_url).query), 'Selected input not present in query string'

    find('input[type="submit"]').click
    assert 'access_public=1'.in?(URI.parse(current_url).query), 'Selected input not present in query string after search'

    find('label[for="access_public"]').click
    assert_not 'access_public=1'.in?(URI.parse(current_url).query), 'Unselected input present in query string'
  end

  test 'restores inputs from URL parameters' do
    visit advanced_search_airports_path(tag_food: 1)

    # The food tag should be visible and selected
    assert_selector 'div.tag-square[data-tag-name="food"]'
    assert_no_selector 'div.tag-square.unselected[data-tag-name="food"]'

    # Other tags should be visible but unselected
    assert_selector 'div.tag-square.unselected[data-tag-name="camping"]'
  end

  test 'sets range input label' do
    visit advanced_search_airports_path

    click_link_or_button 'Runways'
    find_by_id('runway_length').set(5_000)
    assert_equal '5,000ft', find_by_id('runway-length-label').text, 'Range label not updated'
  end

  test 'pages airports' do
    (AirportsController::SEARCH_PAGE_SIZE * 2).times {create(:airport)}
    visit advanced_search_airports_path

    click_link_or_button 'Access'
    find('label[for="access_public"]').click
    find('input[type="submit"]').click

    assert_equal 5, all('.pagination .page-link').count

    # Add a second filter to ensure it gets included in the paging
    find('label[for="access_private"]').click

    click_link_or_button '2'
    assert 'page=1'.in?(URI.parse(current_url).query), 'Second page not in query string after paging'
    assert 'access_private=1'.in?(URI.parse(current_url).query), 'New filter not in query string after paging'
  end

  test 'handles missing airport' do
    visit advanced_search_airports_path

    click_link_or_button 'Location'
    fill_in 'distance_miles', with: '10'
    fill_in 'airport_from', with: 'KAAA'

    find('input[type="submit"]').click

    assert_equal 'Airport with code "KAAA" not found.', find('.results').text, 'Airport not found error text not shown'
  end

  test 'handles missing location inputs' do
    visit advanced_search_airports_path

    click_link_or_button 'Location'
    fill_in 'airport_from', with: 'KAAA'

    find('input[type="submit"]').click

    assert_equal 'All location fields must be entered if filtering by location.', find('.results').text, 'Missing location filter error text not shown'
  end

  test 'switches location types' do
    visit advanced_search_airports_path

    click_link_or_button 'Location'
    assert_selector '#distance_miles'
    assert_no_selector '#distance_hours'
    assert_no_selector '#cruise_speed'

    find('label[for="location_type_hours"]').click
    assert_no_selector '#distance_miles'
    assert_selector '#distance_hours'
    assert_selector '#cruise_speed'
  end

  test 'links to tag anchor' do
    create(:tag, name: :webcam, airport: @airport1)
    visit advanced_search_airports_path

    click_link_or_button 'Access'
    find('label[for="access_public"]').click
    find('input[type="submit"]').click

    # Clicking on the webcam tag should link to the airport page with its anchor set
    click_link_or_button 'Webcam'
    assert_selector '.airport-header'
    assert '#webcam'.in?(current_url), 'Anchor not in URL'
  end

private

  def assert_filter_group_count(count, group)
    assert_equal count.to_s, find("button[data-bs-target=\"#{group}\"] span.badge").text, 'Wrong filter group header badge count'
  end
end
