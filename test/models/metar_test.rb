require 'test_helper'

class MetarTest < ActiveSupport::TestCase
  test 'converts celsius to fahrenheit' do
    metar = create(:metar)

    assert_in_delta 50, metar.temperature, 0.1, 'Temperature not converted from celsius to fahrenheit'
    assert_in_delta 32, metar.dewpoint, 0.1, 'Dewpoint not converted from celsius to fahrenheit'
  end

  test 'is vfr?' do
    assert create(:metar).vfr?, 'VFR not considered VFR conditions'
    assert create(:metar, flight_category: 'MVFR').vfr?, 'MVFR not considered VFR conditions'
    assert_not create(:metar, flight_category: 'IFR').vfr?, 'IFR considered VFR conditions'
    assert_not create(:metar, flight_category: 'LIFR').vfr?, 'LIFR considered VFR conditions'
  end

  test 'is mvfr?' do
    assert_not create(:metar).mvfr?, 'VFR considered MVFR conditions'
    assert create(:metar, flight_category: 'MVFR').mvfr?, 'MVFR not considered MVFR conditions'
    assert_not create(:metar, flight_category: 'IFR').mvfr?, 'IFR considered MVFR conditions'
    assert_not create(:metar, flight_category: 'LIFR').mvfr?, 'LIFR considered MVFR conditions'
  end

  test 'is ifr?' do
    assert_not create(:metar).ifr?, 'VFR considered IFR conditions'
    assert_not create(:metar, flight_category: 'MVFR').ifr?, 'MVFR considered IFR conditions'
    assert create(:metar, flight_category: 'IFR').ifr?, 'IFR not considered IFR conditions'
    assert create(:metar, flight_category: 'LIFR').ifr?, 'LIFR not considered IFR conditions'
  end

  test 'has ceiling' do
    assert_equal 5000, create(:metar).ceiling, 'Did not find overcast cloud layer as ceiling'
  end

  test 'has no ceiling' do
    assert_equal WeatherReport::SKY_CLEAR, create(:metar, cloud_layers: [{coverage: 'FEW', altitude: 2000}]).ceiling, 'Found \'few\' cloud layer as ceiling'
    assert_equal WeatherReport::SKY_CLEAR, create(:metar, cloud_layers: []).ceiling, 'Found ceiling with no cloud layers'
  end

  test 'adds tag to airport on create' do
    assert_difference('Tag.where(name: :weather_report).count', 1) do
      metar = create(:metar)
      assert metar.airport.tags.find_by(name: :weather_report), 'METAR airport does not have weather report tag'
    end
  end

  test 'removes tag from airport on destroy' do
    airport = create(:airport)
    metar = create(:metar, airport: airport)
    taf = create(:taf, airport: airport)

    assert_difference('Tag.count', 0) {metar.destroy!}
    assert_difference('Tag.count', -1) {taf.destroy!}

    assert_nil metar.airport.tags.find_by(name: :weather_report), 'Airport did not have weather report tag removed'
  end
end
