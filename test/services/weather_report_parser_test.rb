require 'test_helper'

class WeatherReportParserTest < ActiveSupport::TestCase
  test 'weather label' do
    assert_equal 'rain', WeatherReportParser.new(create(:metar, weather: 'RA')).weather_label, 'Wrong weather label for rain'
    assert_equal 'light rain', WeatherReportParser.new(create(:metar, weather: '-RA')).weather_label, 'Wrong weather label for light rain'
    assert_equal 'heavy rain, thunderstorm', WeatherReportParser.new(create(:metar, weather: '+RA TS')).weather_label, 'Wrong weather label for heavy rain and thunderstorms'
    assert_equal 'showers in vicinity', WeatherReportParser.new(create(:metar, weather: 'VCSH')).weather_label, 'Wrong weather label for showers in vicinity'
    assert_equal 'blowing snow, ice crystals', WeatherReportParser.new(create(:metar, weather: 'BLSN IC')).weather_label, 'Wrong weather label for blowing snow and ice'
    assert_equal 'rain showers', WeatherReportParser.new(create(:metar, weather: 'SHRA')).weather_label, 'Wrong weather label for rain showers'
    assert_equal '', WeatherReportParser.new(create(:metar, weather: nil)).weather_label, 'Wrong weather label for nil weather string'
  end

  test 'weather category' do
    assert_equal :rain, WeatherReportParser.new(create(:metar)).weather_category, 'Wrong weather category for rain'
    assert_equal :smoke, WeatherReportParser.new(create(:metar, weather: 'HZ +RA')).weather_category, 'Wrong weather category for haze and rain'
    assert_equal :freezing, WeatherReportParser.new(create(:metar, weather: '-FZRA')).weather_category, 'Wrong weather category for freezing rain'
    assert_equal :freezing, WeatherReportParser.new(create(:metar, weather: '+IC')).weather_category, 'Wrong weather category for ice'
    assert_equal :volcano, WeatherReportParser.new(create(:metar, weather: 'VA')).weather_category, 'Wrong weather category for volcanic ash'
    assert_nil WeatherReportParser.new(create(:metar, weather: nil)).weather_category, 'Did not handle nil weather string'
  end
end
