require 'csv'
require 'our_airports/our_airports_api'

class OurAirportsDatabaseParser
  FACILITY_TYPES = {
    'closed_airport' => 'airport',
    'heliport' => 'heliport',
    'large_airport' => 'airport',
    'medium_airport' => 'airport',
    'seaplane_base' => 'seaplane_base',
    'small_airport' => 'airport',
    'balloonport' => 'balloonport',
  }

  def initialize
    @airports = {}
    @airport_references = {}
    @regions = {}
  end

  def download_and_parse
    Dir.mktmpdir do |tmp_directory|
      files = OurAirportsApi.client.airport_data(tmp_directory)

      parse_csv(files[:regions]) {|row| parse_region(row)}
      parse_csv(files[:airports]) {|row| parse_airport(row)}
      parse_csv(files[:runways]) {|row| parse_runway(row)}

      return @airports
    end
  end

private

  def parse_csv(path)
    file = File.read(path)

    CSV.parse(file, headers: true).each do |row|
      yield row
    rescue => error
      Rails.logger.error "Failed parsing airport #{row['local_code']} data in CSV file: #{path}"
      raise error
    end
  end

  def parse_airport(row)
    # Skip closed airports for now as there's no info on what type they were (airport/heliport/other)
    # Maybe in the future it will be worth importing these and filling them out a bit with info.
    return if row['type'] == 'closed'

    # Ignore anything that is not Canada for now
    return unless row['iso_country']&.downcase == 'ca'

    identifier = (row['ident'] || row['local_code']).upcase

    # rubocop:disable Layout/HashAlignment
    @airports[identifier] = {
      our_airports_id: row['id'],
      airport_name:    row['name'],
      icao_code:       row['ident'],
      facility_type:   normalize_facility_type(row['type']),
      facility_use:    'PU', # We have to assume that all airports are public since there's no ownership info in this dataset
      ownership_type:  'PU',
      latitude:        row['latitude_deg'].to_f,
      longitude:       row['longitude_deg'].to_f,
      elevation:       row['elevation_ft'].to_i,
      city:            row['municipality'],
      state:           @regions[row['iso_region']&.upcase],
      country:         row['iso_country']&.downcase,
      city_distance:   nil,
      sectional:       nil,
      fuel_types:      nil,
      activation_date: nil,
      data_source:     :our_airports,
    }
    # rubocop:enable Layout/HashAlignment

    # Keep a separate mapping of the OurAirports ID to the airport's identifer so we can do constant-time lookups in the runways method
    @airport_references[row['id']] = identifier
  end

  def parse_runway(row)
    identifier = @airport_references[row['airport_ref']]
    return unless identifier

    # Don't bother collecting closed runways
    return if row['closed'] == '1'

    @airports[identifier][:runways] ||= []

    @airports[identifier][:runways] << {
      number: "#{row['le_ident']}/#{row['he_ident']}",
      length: row['length_ft'].to_i,
      surface: row['surface']&.upcase,
      lights: (row['lighted'] == '1' ? 'true' : 'false'),
    }
  end

  def parse_region(row)
    @regions[row['code'].upcase] = row['name']
  end

  def normalize_facility_type(facility_type)
    return FACILITY_TYPES[facility_type]
  end
end
