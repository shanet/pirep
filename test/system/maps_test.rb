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

      # Has elevation

      # Has runway

      # Has landing rights

      # Has description
    end

    sleep 1111
  end

  test 'searches airports' do
  end

  test 'filters by type' do
  end

  test 'filters by tag' do
  end

  test 'clear filter group' do
  end

  test 'scrolls filters' do
  end

  test 'switches layers' do
  end

  test 'zooms into airport' do
  end

  test 'visits airport show page' do
  end

  test 'sets state from URL parameters' do
  end

private

  def open_airport(airport)
    coordinates = evaluate_script("mapbox.project([#{airport.longitude}, #{airport.latitude}])")
    find('#map').click(x: coordinates['x'].to_i, y: coordinates['y'].to_i)
  end

  def wait_for_map_ready
    Timeout::timeout(5) do
      loop do
        type = evaluate_script('typeof(mapbox)')
        break unless type == 'undefined'
        sleep 0.1
      end

      # Once the map is ready give it another second to put the airport markers on the map (is there really not a callback for this?!)
      sleep 1
    end
  rescue Timeout::Error
    fail 'Timeout waiting for map to be ready'
  end
end
