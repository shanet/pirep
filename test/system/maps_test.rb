require 'application_system_test_case'

class AirportsTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper

  setup do
    @airport = create(:airport)
  end

  test 'opens drawer' do
    visit maps_path
    wait_for_map_ready
    open_airport(@airport)

    # Verify drawer has airport info
    within('#airport-info') do
      # Has header
      assert_selector '.airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"

      # Has photos
      expected_photo_path = URI.parse(url_for(@airport.photos.first)).path
      actual_photo_path = URI.parse(find('.photo-gallery img')[:src]).path
      assert_equal expected_photo_path, actual_photo_path

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

  test 'searches airports' do
    visit maps_path
    wait_for_map_ready

    # Searching for the airport code should return its search result
    fill_in 'Search airports', with: @airport.code
    find("#search-results li[data-airport-code=\"#{@airport.code}\"]").click

    assert_selector '#airport-info .airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"
  end

  test 'filters by type' do
    heliport = create(:airport, facility_type: :heliport)
    visit maps_path
    wait_for_map_ready

    # By default only airports should be displayed
    assert_equal 1, displayed_airports.count, 'Airports not shown by default'
    assert_equal @airport.code, displayed_airports.first['code']

    # Showing heliports should display the heliport
    click_filter('heliport')
    assert_equal 2, displayed_airports.count, 'Heliports not shown'
    assert displayed_airports.map {|airport| airport['code']}.include?(heliport.code)

    # Deselecting airports should hide the airport leaving only the heliport
    click_filter('airport')
    assert_equal 1, displayed_airports.count, 'Only heliports not shown'
    assert_equal heliport.code, displayed_airports.first['code']

    # Delsecting heliports should show nothing
    click_filter('heliport')
    assert displayed_airports.empty?
  end

  test 'filters by tag' do
    airport = create(:airport)
    create(:tag, airport: airport, name: :camping)
    create(:tag, airport: @airport, name: :golfing)

    visit maps_path
    wait_for_map_ready

    # By default all airports should be shown
    assert_equal 2, displayed_airports.count, 'Not all airports shown by default'

    # Selecting a tag should show only show airports tagged with that tag
    click_filter('camping')
    assert_equal 1, displayed_airports.count, 'Airports not filtered by tag'

    # Selecting another tag should show both again
    click_filter('golfing')
    assert_equal 2, displayed_airports.count, 'Airports not filtered by tag'
  end

  test 'clear filter group' do
    visit maps_path
    wait_for_map_ready

    assert_equal 1, displayed_airports.count
    click_filter('facility_types')
    assert_equal 0, displayed_airports.count
  end

  test 'switches layers' do
    visit maps_path
    wait_for_map_ready

    assert sectional_layer_shown?, 'Sectional layer not shown by default'

    find('#layer-switcher').click
    assert_not sectional_layer_shown?, 'Satellite layer not shown'
    assert_equal 'layer=satellite', URI.parse(current_url).query, 'Layer URL parameter not set'

    # Toggle back to the sectional layer
    find('#layer-switcher').click
    assert sectional_layer_shown?, 'Sectional layer not shown again'
    assert_empty URI.parse(current_url).query, 'Layer URL parameter not removed'
  end

  test 'zooms into airport' do
    visit maps_path
    wait_for_map_ready

    default_zoom_level = map_zoom_level
    open_airport(@airport)

    # Wait for the drawer opening and panning to airport animation to complete
    wait_for_zoom_animation
    click_on 'Zoom In'

    # Wait for zoom animation to finish and check that we're now zoomed in
    wait_for_zoom_animation
    assert_not_equal default_zoom_level, map_zoom_level, 'Map did not zoom in on airport'

    # Zooming in should switch to satellite view
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not set'

    # Zoom back out and wait for the animation to complete
    click_on 'Zoom Out'
    wait_for_zoom_animation

    assert_equal default_zoom_level, map_zoom_level, 'Map did not zoom back out from airport'
    assert_not 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not removed'

    # Zooming in when satellite view is set should return to satellite view
    find('#layer-switcher').click
    click_on 'Zoom In'
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter not set'
    click_on 'Zoom Out'
    assert 'layer=satellite'.in?(URI.parse(current_url).query), 'Layer URL parameter incorrectly removed'
  end

  test 'visits airport show page' do
    visit maps_path
    wait_for_map_ready

    default_zoom_level = map_zoom_level
    find('#layer-switcher').click
    open_airport(@airport)

    within('.airport-drawer-header') do
      # Wait for zoom animation to finish
      click_on 'Zoom In'
      wait_for_zoom_animation

      click_on 'More'
    end

    assert_equal airport_path(@airport.code), URI.parse(current_url).path, 'Did not navigate to airport show page'

    # Go back and give some time for the zoom animation to complete
    go_back
    wait_for_zoom_animation

    # Going back to the map should return to the same state
    assert_selector '#airport-info'
    assert_not_equal default_zoom_level, map_zoom_level, 'Map did not preserve zoom level'
    assert_not sectional_layer_shown?, 'Map did not preserve layer'
  end

  test 'sets state from URL parameters' do
    zoom_level = 15
    latitude = 47.9073174
    longitude = -122.2820940
    filter_facility_types = ['heliport', 'seaplane_base']
    filter_tags = ['food', 'camping']

    visit maps_path(
      layer: :satellite,
      airport: @airport.code,
      zoom: zoom_level,
      coordinates: "#{latitude},#{longitude}",
      filters_facility_types: filter_facility_types.join(','),
      filters_tags: filter_tags.join(',')
    )

    wait_for_map_ready

    assert_equal zoom_level, map_zoom_level, 'Zoom level not set from URL parameter'
    assert_not sectional_layer_shown?, 'Satellite layer not shown from URL parameter'
    assert_selector '#airport-info .airport-drawer-header', text: "#{@airport.code} - #{@airport.name.titleize}"

    assert_in_delta latitude, map_location['lat'], 0.01, 'Map not centered at given URL parameter latitude'
    assert_in_delta longitude, map_location['lng'], 0.01, 'Map not centered at given URL parameter longitude'

    (filter_facility_types + filter_tags).each do |filter|
      assert filter_enabled?(filter), "Filter #{filter} not enabled from URL parameter"
    end
  end

private

  def open_airport(airport)
    coordinates = evaluate_script("mapbox.project([#{airport.longitude}, #{airport.latitude}])")
    find('#map').click(x: coordinates['x'].to_i, y: coordinates['y'].to_i)
  end

  def click_filter(filter_name)
    find("a[data-filter-name=\"#{filter_name}\"]").click
  end

  def filter_enabled?(filter_name)
    return !has_css?("a[data-filter-name=\"#{filter_name}\"].disabled")
  end

  def displayed_airports
    return evaluate_script("mapbox.getSource('airports')._data.features").map {|airport| airport['properties']}
  end

  def sectional_layer_shown?
    return evaluate_script('mapbox.getPaintProperty("seattle", "raster-opacity")') == 1
  end

  def map_zoom_level
    return evaluate_script('mapbox.getZoom()')
  end

  def map_location
    return evaluate_script('mapbox.getCenter()')
  end

  def wait_for_zoom_animation
    sleep 3
  end

  def wait_for_map_ready
    # Once the map is fully ready to use it will populate a data attribute
    find('#map[data-ready="true"]', wait: 10)
  end
end
