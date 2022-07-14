require 'faa/faa_api'

class AirportDatabaseParser
  # These are the ranges for column data as documented in the README at:
  #   * https://www.faa.gov/air_traffic/flight_info/aeronav/aero_data/NASR_Subscription/
  #   * Specifically: https://nfdc.faa.gov/webContent/28DaySub/[year]-[month]-[day]/Layout_Data/apt_rf.txt
  VALUE_RANGES = {
    airport: {
      site_number: [4, 11],
      airport_code: [28, 4],
      airport_name: [134, 50],
      facility_type: [15, 13],
      facility_use: [186, 2],
      ownership_type: [184, 2],
      owner_name: [188, 35],
      owner_phone: [340, 16],
      latitude: [524, 15],
      longitude: [551, 15],
      elevation: [579, 7],
      fuel_type: [901, 40],
    },
    runway: {
      site_number: [4, 11],
      number: [17, 7],
      length: [24, 5],
      surface: [33, 12],
      lights: [61, 5],
    },
    remark: {
      site_number: [4, 11],
      element: [13, 17],
      text: [30, 1500],
    },
  }

  def initialize
    @airports = {}
  end

  def download_and_parse
    Dir.mktmpdir do |tmp_directory|
      parse_file(FaaApi.client.airport_data(tmp_directory))
      return @airports
    end
  end

private

  def parse_file(path)
    # The provided file is annoyingly encoded with latin1 (iso-8859-1) so read it as that and then convert each line to utf-8
    File.foreach(path, encoding: 'iso-8859-1') do |line|
      line.encode!('utf-8')

      type = line[0...3].downcase.to_sym

      case type
        when :apt
          parse_airport(line)
        when :rwy
          parse_runway(line)
        when :rmk
          parse_remark(line)
      end
    end
  end

  def parse_airport(line)
    airport = {}

    VALUE_RANGES[:airport].each do |key, range|
      airport[key] = extract_value_from_line(line, range.first, range.last)
    end

    airport[:latitude] = convert_degrees_minutes_seconds_to_decimal(airport[:latitude])
    airport[:longitude] = convert_degrees_minutes_seconds_to_decimal(airport[:longitude])

    @airports[airport[:site_number]] = airport.tap {|airport_| airport_.delete(:site_number)}
  end

  def parse_runway(line)
    runway = {}

    VALUE_RANGES[:runway].each do |key, range|
      runway[key] = extract_value_from_line(line, range.first, range.last)
    end

    @airports[runway[:site_number]][:runways] ||= []
    @airports[runway[:site_number]][:runways] << runway.tap {|runway_| runway_.delete(:site_number)}
  end

  def parse_remark(line)
    remark = {}

    VALUE_RANGES[:remark].each do |key, range|
      remark[key] = extract_value_from_line(line, range.first, range.last)
    end

    @airports[remark[:site_number]][:remarks] ||= []
    @airports[remark[:site_number]][:remarks] << remark.tap {|remark_| remark_.delete(:site_number)}
  end

  def extract_value_from_line(line, start, length)
    return line[(start - 1)...(start + length - 1)].strip
  end

  def convert_degrees_minutes_seconds_to_decimal(coordinate)
    degrees, minutes, seconds = coordinate.split('-')
    direction = seconds[-1]

    decimal = degrees.to_f + (minutes.to_f / 60) + (seconds.to_f / 3600)
    decimal *= -1 if ['W', 'S'].include?(direction)
    return decimal.round(7)
  end
end
