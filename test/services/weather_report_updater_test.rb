require 'test_helper'

class WeatherReportUpdaterTest < ActiveSupport::TestCase
  setup do
    # The METAR and TAF test fixtures are static files with hardcoded ICAO codes in them
    # so in order to import records we need to create airports with matching ICAO codes.
    @airport_kpae = create(:airport, code: 'PAE', icao_code: 'KPAE')
    @airport_kfhr = create(:airport, code: 'FHR', icao_code: 'KFHR')
    @airport_kawo = create(:airport, code: 'AWO', icao_code: 'KAWO')
  end

  test 'updates weather reports' do
    assert_difference('Metar.count', 3) do
      assert_difference('Taf.count', 3) do
        WeatherReportUpdater.new.update!
      end
    end

    assert @airport_kpae.metar, 'METAR not created for KPAE'
    assert_equal 3, @airport_kpae.tafs.count, 'TAFs not created for KPAE'
    assert @airport_kfhr.metar, 'METAR not created for KFHR'
    assert @airport_kawo.metar, 'METAR not created for KAWO'

    assert @airport_kpae.metar.dewpoint, 'Dewpoint not set in KPAE METAR'
    assert @airport_kpae.metar.observed_at, 'Observed at timestamp not set in KPAE METAR'
    assert @airport_kpae.metar.raw, 'Raw text not set in KPAE METAR'
    assert @airport_kpae.metar.temperature, 'Temperature not set in KPAE METAR'
    assert_equal '-SHRA', @airport_kpae.metar.weather, 'Wrong weather in KPAE METAR'
    assert_equal 'IFR', @airport_kpae.metar.flight_category, 'Wrong flight category in KPAE METAR'
    assert_equal 10, @airport_kpae.metar.visibility, 'Wrong visibility in KPAE Metar'
    assert_equal 110, @airport_kpae.metar.wind_direction, 'Wrong wind direction in KPAE Metar'
    assert_equal 6, @airport_kpae.metar.wind_speed, 'Wrong wind speed in KPAE Metar'
    assert_equal [{'coverage' => 'OVC', 'altitude' => 500}, {'coverage' => 'BKN', 'altitude' => 6000}], @airport_kpae.metar.cloud_layers, 'Cloud layers not parsed correctly for KPAE METAR'
    assert_nil @airport_kpae.metar.ends_at, 'TAF timestamp set in KPAE METAR'
    assert_nil @airport_kpae.metar.starts_at, 'TAF timestamp set in KPAE METAR'
    assert_nil @airport_kpae.metar.wind_gusts, 'Wind gusts populated in KPAE Metar'

    assert @airport_kpae.tafs.first.ends_at, 'Ends at timestamp set in KPAE TAF'
    assert @airport_kpae.tafs.first.raw, 'Raw text not set in KPAE TAF'
    assert @airport_kpae.tafs.first.starts_at, 'Starts at timestamp set in KPAE TAF'
    assert_equal '-VCSH', @airport_kpae.tafs.first.weather, 'Wrong weather in KPAE TAF'
    assert_equal 110, @airport_kpae.tafs.first.wind_direction, 'Wrong wind direction in KPAE TAF'
    assert_equal 6, @airport_kpae.tafs.first.visibility, 'Wrong visibility in KPAE TAF'
    assert_equal 7, @airport_kpae.tafs.first.wind_speed, 'Wrong wind speed in KPAE TAF'
    assert_equal [{'coverage' => 'BKN', 'altitude' => 7000}, {'coverage' => 'OVC', 'altitude' => 9000}], @airport_kpae.tafs.first.cloud_layers, 'Cloud layers not parsed correctly for KPAE TAF'
    assert_nil @airport_kpae.tafs.first.dewpoint, 'Dewpoint set in KPAE TAF'
    assert_nil @airport_kpae.tafs.first.flight_category, 'Flight category set in KPAE TAF'
    assert_nil @airport_kpae.tafs.first.observed_at, 'METAR timestamp set in KPAE TAF'
    assert_nil @airport_kpae.tafs.first.temperature, 'Temperature set in KPAE TAF'
    assert_nil @airport_kpae.tafs.first.wind_gusts, 'Wind gusts populated in KPAE TAF'

    assert_equal [{'coverage' => 'OVX', 'altitude' => 200}], @airport_kawo.metar.cloud_layers, 'Cloud layers not parsed correctly for KAWO METAR'
    assert_equal [{'coverage' => 'CLR', 'altitude' => nil}], @airport_kfhr.metar.cloud_layers, 'Cloud layers not parsed correctly for KFHR METAR'
    assert_equal 15, @airport_kawo.metar.wind_gusts, 'Wrong wind gusts in KAWO METAR'
  end
end
