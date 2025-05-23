require 'application_system_test_case'

class MapTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper

  setup do
    @airport = create(:airport)
    2.times {create(:event, airport: @airport, start_date: 1.day.from_now, end_date: 2.days.from_now)}
  end

  test 'set default map center location' do
    visit map_path
    wait_for_map_ready

    center = evaluate_script('mapbox.getCenter()')
    assert_equal(47.62055376532627, center['lat'], 'Map not centered')
    assert_equal(-122.34936256185215, center['lng'], 'Map not centered')
  end

  test 'opens airport drawer' do
    visit map_path
    wait_for_map_ready
    open_airport(@airport)

    # Verify drawer has airport info
    within('#drawer-content') do
      # Has header
      assert_selector '.airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"

      # Wait for the uncached images to be fetched
      assert_selector('.carousel[data-uncached-photos-loaded="true"]')

      # Has photos
      expected_photo_path = URI.parse(url_for(@airport.contributed_photos.first)).path
      actual_photo_path = URI.parse(find('.carousel img')[:src]).path
      assert_equal expected_photo_path, actual_photo_path

      # Does not have featured photo form
      assert_no_selector '.carousel-item .featured'

      # Has first upcoming event
      assert_selector '.event .card-header a', count: 1
      assert_selector '.event .list-group-item', count: 1, text: @airport.events.upcoming.first.name

      # Has elevation
      assert_selector '.statistics-box', text: "#{number_with_delimiter(@airport.elevation, delimiter: ',')}ft"

      # Has runway
      assert_selector '.statistics-box', text: "#{number_with_delimiter(@airport.runways.first.length, delimiter: ',')}ft"

      # Has landing rights
      assert_selector '.landing-rights', text: "Access: #{Airport::LANDING_RIGHTS_TYPES[@airport.landing_rights][:long_description]}"

      # Has description
      assert_selector '.EasyMDEContainer', text: @airport.description
    end
  end

  test 'opens, closes, and re-opens airport drawer' do
    visit map_path
    wait_for_map_ready
    open_airport(@airport)

    within('#drawer-content') do
      assert_selector '.EasyMDEContainer', count: 1
      click_link_or_button 'Zoom In'
    end

    # Close and re-open the drawer
    find('#airport-drawer .handle > button').click
    open_airport(@airport)

    # Upon the re-opening the drawer, there should still be one description field and the zoom button label was not changed
    within('#drawer-content') do
      assert_selector '.EasyMDEContainer', count: 1
      click_link_or_button 'Zoom Out'
    end
  end

  test 'opens airport drawer for hidden airport' do
    # Seaplane bases won't be visible by default
    seaplane = create(:airport, name: 'Seaplane base', facility_type: :seaplane_base, latitude: @airport.latitude + 0.11)

    # Heliports should never be in the hidden airports layer
    heliport = create(:airport, name: 'Heliport', facility_type: :heliport, latitude: @airport.latitude - 0.11)

    visit map_path
    wait_for_map_ready
    map_set_zoom_level(6)

    # Hidden airports not shown when zoomed out on the map so clicking on the position for the marker should do nothing
    open_airport(seaplane)
    assert_no_selector '#drawer-content .airport-drawer-header'

    # Zoom in sufficiently so the hidden airports layer is shown
    map_set_zoom_level(10)
    assert_equal 10, map_zoom_level, 'Map did not zoom in for hidden airports layer to be shown'
    open_airport(seaplane)

    assert seaplane.code.in?(airport_markers('airports_hidden').pluck('code')), 'Hidden airport marker not shown on map'
    assert_not heliport.code.in?(airport_markers('airports_hidden').pluck('code')), 'Heliport marker shown in hidden airports layer'

    within('#drawer-content') do
      assert_selector '.airport-drawer-header', text: "#{seaplane.code} - #{seaplane.name.titleize}"
    end
  end

  # The login drawer should be open by default when the `#login` anchor is present in the URL
  test 'opens login drawer' do
    visit map_path(params: {drawer: :login})
    assert_selector '#login-tabs'
  end

  test 'opens about drawer' do
    visit map_path(params: {drawer: :about})
    assert_selector '#about'
  end

  test 'opens origin drawer' do
    visit map_path(params: {drawer: :origin})
    assert_selector '#origin'
  end

  test 'searches airports' do
    visit map_path
    wait_for_map_ready

    # Searching for the airport code should return its search result
    fill_in 'Search airports', with: @airport.code
    find("#search-results li[data-airport-code=\"#{@airport.code}\"]").click

    assert_selector '#drawer-content .airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"
  end

  test 'goes to coordinates' do
    visit map_path
    wait_for_map_ready

    # Entering coordinates into the search should go directly to them
    fill_in 'Search airports', with: "#{@airport.latitude}, #{@airport.longitude}"

    # We need to wait for the map to move before checking the current location but the only UI element to check against is that the layer switcher
    # was changed to the map icon as the sectional layer is turned off. This makes this test dependent on the sectional layer initially being shown.
    assert_selector '#layer-switcher i[class="map-icon fas fa-map"]'
    assert_no_selector '#search-results'

    center = map_location
    assert_in_delta center['lat'], @airport.latitude, 0.1, 'Search did not go to given coordinates'
    assert_in_delta center['lng'], @airport.longitude, 0.1, 'Search did not go to given coordinates'
  end

  test 'filters by type' do
    heliport = create(:airport, facility_type: :heliport)
    visit map_path
    wait_for_map_ready

    # By default only airports should be displayed
    assert_equal 1, airport_markers.count, 'Airports not shown by default'
    assert_equal @airport.code, airport_markers.first['code']

    # Showing heliports should display the heliport
    click_filter('heliport')
    assert_equal 2, airport_markers.count, 'Heliports not shown'
    assert airport_markers.pluck('code').include?(heliport.code)

    # Deselecting airports should hide the airport leaving only the heliport
    click_filter('airport')
    assert_equal 1, airport_markers.count, 'Only heliports not shown'
    assert_equal heliport.code, airport_markers.first['code']

    # Delsecting heliports should show nothing
    click_filter('heliport')
    assert airport_markers.empty?
  end

  test 'filters by tag' do
    airport = create(:airport)
    create(:tag, airport: airport, name: :camping)
    create(:tag, airport: @airport, name: :golfing)

    visit map_path
    wait_for_map_ready

    # By default all airports should be shown and the populated tag filter should be enabled
    assert_equal 2, airport_markers.count, 'Not all airports shown by default'
    assert_selector '.filter[data-filter-group="tags"][data-filter-name="populated"]:not(.disabled)'

    # Selecting a tag should show only show airports tagged with that tag
    click_filter('camping')
    assert_equal 1, airport_markers.count, 'Airports not filtered by tag'
    assert_selector '.filter[data-filter-group="tags"][data-filter-name="populated"].disabled'

    # The cooresponding origin info tag square filter should be enabled as well
    assert tag_square_filter_enabled?('camping'), 'Origin info tag square filter not enabled'

    # Selecting another tag should show both again
    click_filter('golfing')
    assert_equal 2, airport_markers.count, 'Airports not filtered by tag'

    # Disabling the populated filter explicitly should hide all airports
    click_filter('tags')
    click_filter('populated')
    assert_equal 0, airport_markers.count, 'Airports not filtered by tag'
  end

  test 'filters by tag in origin info' do
    visit map_path
    wait_for_map_ready

    find_by_id('hamburger-icon').click
    click_link_or_button('Getting Started')

    within('#origin') do
      # There should be a tag filter for each of the origin tags
      assert_selector '#origin .tag-square', count: Tag.origin_tags.count

      find('.tag-square.unselected[data-tag-name="golfing"]').click
      assert tag_square_filter_enabled?('golfing'), 'Origin info tag square filter not enabled when clicked'
    end

    assert filter_enabled?('golfing'), 'Filter not enabled when origin info filter enabled'
  end

  test 'clear filter group' do
    visit map_path
    wait_for_map_ready

    assert_equal 1, airport_markers.count
    click_filter('facility_types')
    assert_selector '.filter[data-filter-group="facility_types"][data-filter-name="airport"].disabled'
    assert_equal 0, airport_markers.count

    # Disabling all tag filters should enable the populated filter
    click_filter('airport')
    click_filter('food')
    click_filter('tags')
    assert_selector '.filter[data-filter-group="tags"][data-filter-name="populated"]:not(.disabled)'
    assert_equal 1, airport_markers.count
  end

  test 'switches layers' do
    visit map_path
    wait_for_map_ready

    assert chart_layer_shown?(:sectional), 'Sectional layer not shown by default'

    find_by_id('layer-switcher').click
    assert_not chart_layer_shown?(:sectional), 'Satellite layer not shown'
    assert_equal 'layer=satellite', URI.parse(current_url).query, 'Layer URL parameter not set'

    # Toggle back to the sectional layer
    find_by_id('layer-switcher').click
    assert chart_layer_shown?(:sectional), 'Sectional layer not shown again'
    assert_empty URI.parse(current_url).query, 'Layer URL parameter not removed'
  end

  test 'shows terminal area charts when soomed in' do
    visit map_path
    wait_for_map_ready

    assert chart_layer_shown?(:sectional), 'Sectional layer not shown by default'
    open_airport(@airport)

    # Zoom into the airport then switch back to chart view to confirm that the terminal area chart is shown when zoomed in sufficiently
    click_link_or_button 'Zoom In'
    find_by_id('layer-switcher').click
    assert chart_layer_shown?(:terminal), 'Terminal area chart not shown when zoomed in'
  end

  test 'zooms into airport' do
    visit map_path
    wait_for_map_ready

    default_zoom_level = map_zoom_level
    open_airport(@airport)

    # Zoom in on the airport and then check that we're now zoomed in
    click_link_or_button 'Zoom In'
    assert_not_equal default_zoom_level, map_zoom_level, 'Map did not zoom in on airport'

    # Zooming in should switch to satellite view
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not set'

    click_link_or_button 'Zoom Out'

    assert_equal default_zoom_level, map_zoom_level, 'Map did not zoom back out from airport'
    assert_not 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not removed'

    # Zooming in when satellite view is set should return to satellite view
    find_by_id('layer-switcher').click
    click_link_or_button 'Zoom In'
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not set'
    click_link_or_button 'Zoom Out'
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter incorrectly removed'
  end

  test 'visits airport show page' do
    visit map_path
    wait_for_map_ready

    default_zoom_level = map_zoom_level
    find_by_id('layer-switcher').click
    open_airport(@airport)

    within('.airport-drawer-header') do
      click_link_or_button 'Zoom In'

      # Wait for the zoom level in the URL to be updated or the map won't return to the zoom level when returning to the page
      # Capybara's synchronize method will keep re-running while an exception is raised. Since there's nothing to key off
      # of for a URL param change, this is the best we can do.
      first('div').synchronize do
        # These are floats so compare the difference between them rather than equality
        url_zoom_level = current_url.split('#').last.split('/').first.to_f
        raise Capybara::ElementNotFound if (url_zoom_level - default_zoom_level).abs < 0.1
      end

      click_link_or_button 'More'
    end

    assert_equal airport_path(@airport.code), URI.parse(current_url).path, 'Did not navigate to airport show page'

    # Going back to the map should return to the same state
    go_back
    wait_for_map_ready

    assert_selector '.airport-drawer-header'
    assert_not_equal default_zoom_level, map_zoom_level, 'Map did not preserve zoom level'
    assert_not chart_layer_shown?(:sectional), 'Map did not preserve layer'
  end

  test 'sets state from URL parameters' do
    zoom_level = 15
    latitude = 47.9073174
    longitude = -122.2820940
    filter_facility_types = ['heliport', 'seaplane_base']
    filter_tags = ['food', 'camping']

    visit map_path(
      layer: :satellite,
      airport: @airport.code,
      zoom: zoom_level,
      coordinates: "#{latitude},#{longitude}",
      filters_facility_types: filter_facility_types.join(','),
      filters_tags: filter_tags.join(',')
    )

    wait_for_map_ready

    assert_equal zoom_level, map_zoom_level, 'Zoom level not set from URL parameter'
    assert_not chart_layer_shown?(:sectional), 'Satellite layer not shown from URL parameter'
    assert_selector '#drawer-content .airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"

    assert_in_delta latitude, map_location['lat'], 0.01, 'Map not centered at given URL parameter latitude'
    assert_in_delta longitude, map_location['lng'], 0.01, 'Map not centered at given URL parameter longitude'

    (filter_facility_types + filter_tags).each do |filter|
      assert filter_enabled?(filter), "Filter #{filter} not enabled from URL parameter"
    end

    # The filters in the origin info drawer should be enabled as well
    find_by_id('hamburger-icon').click
    click_link_or_button('Getting Started')

    within('#origin') do
      filter_tags.select {|tag| tag.in?(Tag.origin_tags.keys)}.each do |tag|
        assert tag_square_filter_enabled?(tag), "Tag square filter #{tag} not enabled from URL parameter"
      end
    end
  end

  test 'adds unmapped airport' do
    visit map_path
    wait_for_map_ready

    find_by_id('new-airport-button').click

    # Select a location for the new airport on the map
    find('button.select-coordinates').click # rubocop:disable Capybara/SpecificActions

    assert filter_enabled?('public_'), 'Public airport filter not enabled before adding unmapped airport'
    assert filter_enabled?('private_'), 'Private airport filter not enabled before adding unmapped airport'

    find_by_id('map').click(x: 0, y: 0)
    assert_equal 16, map_zoom_level, 'Map not zoomed in on selected coordinates'

    within('#new-airport') do
      assert_match(/Location: -?\d+(\.\d+)?, -?\d+(\.\d+)? \/ \d+ft/, find('.coordinates').text, 'Location label not set on selection')

      find_by_id('airport_name').fill_in(with: 'Secret Airport')
      find('#airport_landing_rights_restricted + label').click
      find_by_id('airport_landing_requirements').fill_in(with: 'Call 867-5309')

      click_link_or_button 'Submit'
    end

    assert_selector '.alert', text: 'New airport added to map'
  end

  test 'displays annotations for airport' do
    # Create another airport with annotations to ensure only one airport's annotations are shown, but far enough away that it won't be in the same viewport and still be displayed
    create(:airport, latitude: @airport.latitude + 10, longitude: @airport.longitude + 10)

    visit map_path
    wait_for_map_ready

    # There should be no annotations on the map when first loaded zoomed out
    assert_no_selector '.annotation'

    open_airport(@airport)
    click_link_or_button 'Zoom In'
    assert_selector '.annotation', count: @airport.annotations.count

    # Clicking on an annotation label should not enter editing mode
    first('.annotation .label').click
    assert_no_selector '.annotation.editing'

    # Zooming out should remove the annotations
    click_link_or_button 'Zoom Out'
    assert_no_selector '.annotation'
  end

  test 'enters 3D mode' do
    visit map_path
    wait_for_map_ready

    assert_selector '#map-pitch-button', text: '3D'

    find_by_id('map-pitch-button').click
    assert_selector '#map-pitch-button', text: '2D'
    assert_equal 45, map_pitch, 'Map not in 3D mode'

    find_by_id('map-pitch-button').click
    assert_selector '#map-pitch-button', text: '3D'
    assert_equal 0, map_pitch, 'Map pitch not reset'
  end

  test 'has meta and opengraph tags' do
    visit map_path

    # Sanity check on the meta tags being present
    assert_equal Rails.configuration.meta_title, find('meta[name="title"]', visible: false)[:content], 'Unexpected meta name'
    assert_equal Rails.configuration.meta_description, find('meta[name="description"]', visible: false)[:content], 'Unexpected meta description'
    assert find('meta[property="og:title"]', visible: false)[:content].present?, 'Opengraph tags not present'
  end

  test 'shows origin drawer on first visit' do
    visit map_path
    assert_selector '#drawer-content #origin'

    visit map_path
    assert_no_selector '#drawer-content #origin'
  end

  test 'changes theme' do
    visit map_path

    # It should be light mode by default
    assert_no_selector 'body[data-bs-theme="dark]'

    find_by_id('hamburger-icon').click
    assert find_by_id('color-scheme-auto').checked?, 'Auto mode control not selected by default'

    # Switch to dark mode
    find('label[for="color-scheme-dark"]').click
    assert_selector 'body[data-bs-theme="dark"]'

    # The menu should still be open after clicking the button
    assert_selector '#hamburger-menu'
  end

private

  def open_airport(airport)
    coordinates = evaluate_script("mapbox.project([#{airport.longitude}, #{airport.latitude}])")

    # Selenium uses the in-view center point of the element as the origin but the values from Mapbox are based
    # on the origin at the top-left so we need to adjust by subtracting the radius to the center of the element
    size = find_by_id('map').native.size
    coordinates['x'] -= size[:width] / 2
    coordinates['y'] -= size[:height] / 2

    find_by_id('map').click(x: coordinates['x'].to_i, y: coordinates['y'].to_i)
  end

  def click_filter(filter_name)
    find("a[data-filter-name=\"#{filter_name}\"]").click
  end

  def filter_enabled?(filter_name)
    return !has_css?("a[data-filter-name=\"#{filter_name}\"].disabled")
  end

  def tag_square_filter_enabled?(tag_name)
    return has_css?(".tag-square[data-tag-name=\"#{tag_name}\"]:not(.unselected)")
  end

  def airport_markers(airports_layer='airports_visible')
    return evaluate_script("mapbox.getSource('#{airports_layer}')._data.features").pluck('properties')
  end

  def chart_layer_shown?(chart_layer)
    return evaluate_script("mapbox.getPaintProperty('#{chart_layer}', 'raster-opacity')") == 1
  end

  def map_zoom_level
    return evaluate_script('mapbox.getZoom()')
  end

  def map_set_zoom_level(zoom_level)
    return execute_script("mapbox.setZoom(#{zoom_level})")
  end

  def map_pitch
    return evaluate_script('mapbox.getPitch()')
  end

  def map_location
    return evaluate_script('mapbox.getCenter()')
  end
end
