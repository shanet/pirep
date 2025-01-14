require 'test_helper'

class AirportsHelperTest < ActionView::TestCase
  include AirportsHelper

  setup do
    @current_user = nil
  end

  test 'show notices' do
    assert_not show_notices?(create(:airport)), 'Normal airport shows notices'
    assert show_notices?(create(:airport, :empty)), 'Empty airport does not show notices'
    assert show_notices?(create(:airport, :closed)), 'Closed airport does not show notices'
    assert show_notices?(create(:airport, :unmapped)), 'Unmapped airport does not show notices'
  end

  test 'version author when unknown' do
    unknown = create(:unknown)
    known = create(:known)

    with_versioning do
      version = create(:airport).versions.first

      # A nil whodunnit should return a default string
      assert_equal 'System', version_author(version)

      version.update!(whodunnit: unknown.id)
      assert users_show_user_path(unknown).in?(version_author(version))

      version.update!(whodunnit: known.id)
      assert users_show_user_path(known).in?(version_author(version))
    end
  end

  test 'version author when admin' do
    @current_user = create(:admin)
    unknown = create(:unknown)
    known = create(:known)

    with_versioning do
      version = create(:airport).versions.first

      # A nil whodunnit should return a default string
      assert_equal 'System', version_author(version)

      version.update!(whodunnit: unknown.id)
      assert manage_user_path(unknown).in?(version_author(version))

      version.update!(whodunnit: known.id)
      assert manage_user_path(known).in?(version_author(version))
    end
  end

  test 'diffs strings and arrays' do
    assert diff('foo', 'bar').left, 'Handled diff of strings'
    assert diff([{label: 'foo', latitude: 0, longitude: 0}], [{label: 'bar', latitude: 0, longitude: 0}]).left, 'Handled diff of annotations'
  end

  test 'opengraph description' do
    airport = create(:airport)
    assert_equal airport.description, opengraph_description(airport), 'Did not use airport description'

    airport.update!(description: "1\n2\n3")
    assert_equal "1\n2", opengraph_description(airport), 'Used more than two lines from description'

    airport.update!(description: '[example.com](https://example.com)')
    assert_equal 'example.com', opengraph_description(airport), 'Did not remove markdown from description'

    airport.update!(description: nil)
    assert opengraph_description(airport).start_with?(airport.name.titleize)

    airport.tags << create(:tag, name: :unmapped)
    assert 'unmapped'.in?(opengraph_description(airport)), 'Unmapped language not used for unmapped airport'
  end

  test 'opengraph image' do
    airport = create(:airport, contributed_photos: nil)

    # Use the site icon if there are no photos for the airport
    assert_equal image_url('logo_small.png'), opengraph_image(airport), 'Did not use site icon'

    # Use external photos next
    airport.external_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))
    assert_equal cdn_url_for(airport.external_photos.first), opengraph_image(airport), 'Did not use external photo first'

    # Then contributed photos
    airport.contributed_photos.attach(Rack::Test::UploadedFile.new('test/fixtures/files/image.png', 'image/png'))
    assert_equal cdn_url_for(airport.contributed_photos.first), opengraph_image(airport), 'Did not use contributed photo first'

    # Finally, prefer a featured photo
    airport.update!(featured_photo: airport.contributed_photos.first)
    assert_equal cdn_url_for(airport.featured_photo), opengraph_image(airport), 'Did not use featured photo first'
  end

  test 'fuel label' do
    airport = create(:airport, fuel_types: nil)
    assert_equal 'None', fuel_label(airport), 'Incorrect fuel label for airport without fuel'
  end

  test 'ios' do
    user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1'
    assert ios?(OpenStruct.new(user_agent: user_agent)), 'Did not detect iOS user agent' # rubocop:disable Style/OpenStructUse

    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 13.3; rv:112.0) Gecko/20100101 Firefox/112.0'
    assert_not ios?(OpenStruct.new(user_agent: user_agent)), 'Incorrectly detected iOS user agent' # rubocop:disable Style/OpenStructUse
  end

  test 'foreflight url' do
    airport = create(:airport)
    assert_equal "foreflightmobile://maps/search?q=APT@#{airport.icao_code}", foreflight_url(airport), 'Wrong ForeFlight URL for airport with ICAO code'

    airport = create(:airport, icao_code: nil)
    assert_equal "foreflightmobile://maps/search?q=APT@#{airport.code}", foreflight_url(airport), 'Wrong ForeFlight URL for airport without ICAO code'

    airport = create(:airport, :unmapped)
    assert_equal "foreflightmobile://maps/search?q=#{airport.latitude}/#{airport.longitude}", foreflight_url(airport), 'Wrong ForeFlight URL for unmapped airport'
  end

  test 'recurring event to_s' do
    assert_equal '', recurring_event_to_s(create(:event)), 'Wrong recurring event label for static event'

    event = create(:event, :recurring, recurring_cadence: :yearly)
    assert_equal "Repeats every year on the last Monday of #{event.start_date.strftime('%B')}", recurring_event_to_s(event), 'Wrong recurring event label for recurring event'

    event = create(:event, :recurring, recurring_cadence: :yearly, recurring_week_of_month: 5)
    assert_equal "Repeats every year on the fifth Monday of #{event.start_date.strftime('%B')}", recurring_event_to_s(event), 'Wrong recurring event label for recurring event'

    event = create(:event, :recurring, recurring_cadence: :monthly, recurring_day_of_month: 1, recurring_week_of_month: nil)
    assert_equal 'Repeats every month on the 1st', recurring_event_to_s(event), 'Wrong recurring event label for recurring event'

    event = create(:event, :recurring, recurring_cadence: :weekly, recurring_interval: 2)
    assert_equal 'Repeats every two weeks', recurring_event_to_s(event), 'Wrong recurring event label for recurring event'
  end

  test 'weather icon' do
    airport = create(:airport)

    # First tries to find icon with weather category
    airport.metar = create(:metar, airport: airport, weather: 'FZRA')
    assert_equal 'fa-person-skating', weather_icon(airport)

    # Then checks wind values
    airport.metar = create(:metar, airport: airport, weather: nil, wind_gusts: 25)
    assert_equal 'fa-wind', weather_icon(airport)

    # Then flight category
    airport.metar = create(:metar, airport: airport, weather: nil, flight_category: 'LIFR')
    assert_equal 'fa-cloud', weather_icon(airport)

    # Then time of day (night hours)
    travel_to(Time.zone.now.in_time_zone(airport.timezone).change(hour: 20)) do
      # Finally, clear sky or not
      airport.metar = create(:metar, airport: airport, weather: nil, cloud_layers: [])
      assert_equal 'fa-moon', weather_icon(airport)

      airport.metar = create(:metar, airport: airport, weather: nil)
      assert_equal 'fa-cloud-moon', weather_icon(airport)
    end

    # Daytime hours
    travel_to(Time.zone.now.in_time_zone(airport.timezone).change(hour: 12)) do
      airport.metar = create(:metar, airport: airport, weather: nil, cloud_layers: [])
      assert_equal 'fa-sun', weather_icon(airport)

      airport.metar = create(:metar, airport: airport, weather: nil)
      assert_equal 'fa-cloud-sun', weather_icon(airport)
    end
  end

  test 'cloud layers to_s' do
    assert_equal 'Few @ 3,000ft, Overcast @ 5,000ft', cloud_layers_to_s(create(:metar)), 'Wrong cloud layers string'
    assert_equal '', cloud_layers_to_s(create(:metar, cloud_layers: [])), 'Wrong cloud layers string for no clouds'
  end

private

  def current_user
    return @current_user
  end
end
