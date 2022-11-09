require 'csv'
require 'faa/faa_api'

class AirportDatabaseParser
  def initialize
    @airports = {}
  end

  def download_and_parse
    Dir.mktmpdir do |tmp_directory|
      files = FaaApi.client.airport_data(tmp_directory)

      parse_csv(files[:airports]) {|row| parse_airport(row)}
      parse_csv(files[:runways]) {|row| parse_runway(row)}
      parse_csv(files[:remarks]) {|row| parse_remark(row)}

      return @airports
    end
  end

private

  def parse_csv(path)
    # The provided file is annoyingly encoded with latin1 (iso-8859-1) so read it as that and then convert to utf-8
    file = File.read(path, encoding: 'iso-8859-1').encode('utf-8')

    CSV.parse(file, headers: true).each do |row|
      yield row
    rescue => error
      Rails.logger.error "Failed parsing airport #{row['ARPT_ID']} data in CSV file: #{path}"
      raise error
    end
  end

  def parse_airport(row)
    # Anything without an airport ID is either malformed or a blank line in the CSV
    return if row['ARPT_ID'].blank?

    # rubocop:disable Layout/HashAlignment
    @airports[row['ARPT_ID'].upcase] = {
      airport_name:    row['ARPT_NAME'],
      facility_type:   row['SITE_TYPE_CODE'].upcase,
      facility_use:    row['FACILITY_USE_CODE'].upcase,
      ownership_type:  row['OWNERSHIP_TYPE_CODE'].upcase,
      latitude:        row['LAT_DECIMAL'].to_f,
      longitude:       row['LONG_DECIMAL'].to_f,
      elevation:       row['ELEV'].to_i,
      city:            row['CITY'],
      state:           row['COUNTY_ASSOC_STATE'].upcase,
      city_distance:   row['DIST_CITY_TO_AIRPORT'].to_f,
      sectional:       row['CHART_NAME'],
      fuel_types:      row['FUEL_TYPES'],
      activation_date: (row['ACTIVATION_DATE'].present? ? DateTime.strptime(row['ACTIVATION_DATE'], '%Y/%m') : nil),
    }
    # rubocop:enable Layout/HashAlignment
  end

  def parse_runway(row)
    return if row['ARPT_ID'].blank?

    @airports[row['ARPT_ID']][:runways] ||= []

    @airports[row['ARPT_ID']][:runways] << {
      number: row['RWY_ID'],
      length: row['RWY_LEN'].to_i,
      surface: row['SURFACE_TYPE_CODE'].upcase,
      lights: row['RWY_LGT_CODE'].upcase,
    }
  end

  def parse_remark(row)
    return if row['ARPT_ID'].blank?

    @airports[row['ARPT_ID']][:remarks] ||= []

    @airports[row['ARPT_ID']][:remarks] << {
      element: row['ELEMENT'].presence || row['LEGACY_ELEMENT_NUMBER'],
      text: row['REMARK'],
    }
  end
end
