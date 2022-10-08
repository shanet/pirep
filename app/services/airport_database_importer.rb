require 'faa/faa_api'

class AirportDatabaseImporter
  MILITARY_OWNERSHIP_TYPES = ['MA', 'MN', 'MR', 'CG']

  def initialize(airports)
    @airports = airports
    @current_data_cycle = FaaApi.client.current_data_cycle
  end

  def load_database
    @airports.each do |site_number, airport_data|
      airport = update_airport(site_number, airport_data)

      update_tags(airport)

      (airport_data[:runways] || []).each do |runway|
        update_runway(airport, runway)
      end

      (airport_data[:remarks] || []).each do |remark|
        update_remark(airport, remark)
      end
    end

    tag_closed_airports
  end

private

  def update_airport(site_number, airport_data)
    # First try to find existing airports by their site number. Unfortunately this number doesn't seem to be very stable so fallback to the airport code
    # and if that fails it must be a new airport we haven't seen before (yay!).
    airport = Airport.find_by(site_number: site_number) || Airport.find_by(code: airport_data[:airport_code]) || Airport.new

    # Normalize the facility type to the options we use for filtering
    if airport_data[:ownership_type].in?(MILITARY_OWNERSHIP_TYPES)
      airport_data[:facility_type] = :military
    else
      airport_data[:facility_type] = airport_data[:facility_type].parameterize.underscore
    end

    airport.update!({
      site_number: site_number,
      code: airport_data[:airport_code],
      name: airport_data[:airport_name],
      facility_type: airport_data[:facility_type],
      facility_use: airport_data[:facility_use],
      ownership_type: airport_data[:ownership_type],
      owner_name: airport_data[:owner_name],
      owner_phone: airport_data[:owner_phone],
      latitude: airport_data[:latitude],
      longitude: airport_data[:longitude],
      coordinates: [airport_data[:latitude], airport_data[:longitude]],
      elevation: airport_data[:elevation].to_i,
      fuel_type: airport_data[:fuel_type],
      landing_rights: (airport_data[:facility_use] == 'PR' ? :private_ : :public_),
      faa_data_cycle: @current_data_cycle,
    })

    return airport
  end

  def update_tags(airport)
    # Tag public and private airports
    unless airport.ownership_type.in?(MILITARY_OWNERSHIP_TYPES)
      tag = (airport.facility_use == 'PR' ? :private_ : :public_)
      airport.tags << Tag.new(name: tag)
    end

    # Tag airports without any user contributed data yet
    if airport.empty? # rubocop:disable Style/GuardClause
      airport.tags << Tag.new(name: :empty)
    end
  end

  def update_runway(airport, runway_data)
    runway = airport.runways.find_by(number: runway_data[:number]) || Runway.new(airport: airport)

    runway.update!({
      number: runway_data[:number],
      length: runway_data[:length],
      surface: runway_data[:surface],
      lights: runway_data[:lights],
    })
  end

  def update_remark(airport, remark_data)
    remark = airport.remarks.find_by(element: remark_data[:element]) || Remark.new(airport: airport)

    remark.update!({
      element: remark_data[:element],
      text: remark_data[:text],
    })
  end

  def tag_closed_airports
    # This function saddens me to write, but it's interesting data to track airports have closed.
    # We can do this by checking which airports have their data cycle not set to the current one which
    # would denote it had been removed from the FAA's database. This will serve as roughly the date it
    # was closed and we can then add a closed tag to it for display on the map.
    closed_airports = Airport.where('faa_data_cycle < ?', @current_data_cycle)
      .where("NOT EXISTS (#{Tag.select('1').where(name: :closed).where('tags.airport_id = airports.id').to_sql})")

    closed_airports.each do |airport|
      Tag.create!(name: :closed, airport: airport)
    end
  end
end
