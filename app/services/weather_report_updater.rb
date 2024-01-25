require 'aviation_weather/aviation_weather_api'

class WeatherReportUpdater
  def update!
    Dir.mktmpdir do |directory|
      metars_updated = update_metars!(directory)
      tafs_updated = update_tafs!(directory)

      Rails.logger.info("METARs updated: #{metars_updated}\nTAFs updated: #{tafs_updated}")
    end
  end

private

  def update_metars!(directory)
    metars_path = AviationWeatherApi.client.metars(directory)
    airports_updated = 0

    xml = Nokogiri::XML(File.open(metars_path)) do |config| # rubocop:disable Style/SymbolProc
      config.strict
    end

    xml.xpath('//response/data/METAR').each do |metar|
      station_id = metar.at_xpath('station_id').text.upcase
      airport = Airport.find_by(code: station_id) || Airport.find_by(icao_code: station_id)

      if airport
        Rails.logger.info("Updating METAR for #{station_id}")
      else
        Rails.logger.info("Airport not found for METAR station \"#{station_id}\", skipping")
        next
      end

      cloud_layers = extract_cloud_layers(metar)

      ApplicationRecord.transaction do
        airport.metar&.destroy!

        airport.metar = Metar.new({
          cloud_layers: cloud_layers,
          dewpoint: metar.at_xpath('dewpoint_c')&.text&.to_f,
          flight_category: metar.at_xpath('flight_category').text,
          observed_at: Time.zone.parse(metar.at_xpath('observation_time').text),
          raw: metar.at_xpath('raw_text').text,
          temperature: metar.at_xpath('temp_c')&.text&.to_f,
          visibility: metar.at_xpath('visibility_statute_mi')&.text&.to_i,
          weather: metar.at_xpath('wx_string')&.text,
        }.merge(extract_winds(metar)))

        airports_updated += 1
      end
    end

    return airports_updated
  end

  def update_tafs!(directory)
    tafs_path = AviationWeatherApi.client.tafs(directory)
    airports_updated = 0

    xml = Nokogiri::XML(File.open(tafs_path)) do |config| # rubocop:disable Style/SymbolProc
      config.strict
    end

    xml.xpath('//response/data/TAF').each do |taf|
      station_id = taf.at_xpath('station_id').text.upcase
      airport = Airport.find_by(code: station_id) || Airport.find_by(icao_code: station_id)

      if airport
        Rails.logger.info("Updating TAF for #{station_id}")
      else
        Rails.logger.info("Airport not found for TAF station \"#{station_id}\", skipping")
        next
      end

      ApplicationRecord.transaction do
        airport.tafs.destroy_all

        taf.xpath('forecast').each do |forecast|
          cloud_layers = extract_cloud_layers(forecast)

          airport.tafs << Taf.new({
            cloud_layers: cloud_layers,
            ends_at: Time.zone.parse(forecast.at_xpath('fcst_time_to').text),
            raw: taf.at_xpath('raw_text').text,
            starts_at: Time.zone.parse(forecast.at_xpath('fcst_time_from').text),
            visibility: forecast.at_xpath('visibility_statute_mi')&.text&.to_i,
            weather: forecast.at_xpath('wx_string')&.text,
          }.merge(extract_winds(forecast)))
        end
      end

      airports_updated += 1
    end

    return airports_updated
  end

  def extract_cloud_layers(node)
    return node.xpath('./sky_condition').map do |sky_condition|
      coverage = sky_condition.attribute_nodes.find {|attribute| attribute.name == 'sky_cover'}.value.upcase
      altitude = sky_condition.attribute_nodes.find {|attribute| attribute.name == 'cloud_base_ft_agl'}&.value&.to_i

      # If obscured sky read the altitude from the vertical visibility node
      altitude = node.at_xpath('vert_vis_ft')&.text&.to_i if coverage == 'OVX'

      next {coverage: coverage, altitude: altitude}
    end.sort_by {|cloud_layer| cloud_layer[:altitude] || (2**32)} # Default to a max integer value for clear skies # rubocop:disable Style/MultilineBlockChain
  end

  def extract_winds(node)
    return {
      wind_direction: (node.at_xpath('wind_dir_degrees')&.text == 'VRB' ? WeatherReport::WINDS_VARIABLE : node.at_xpath('wind_dir_degrees')&.text&.to_i),
      wind_gusts: node.at_xpath('wind_gust_kt')&.text&.to_i,
      wind_speed: node.at_xpath('wind_speed_kt')&.text&.to_i,
    }
  end
end
