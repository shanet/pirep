require 'faa/faa_api'

class AirportDatabaseImporter
  FACILITY_TYPES = {
    'A' => :airport,
    'B' => :balloonport,
    'C' => :seaplane_base,
    'G' => :gliderport,
    'H' => :heliport,
    'U' => :ultralight,
  }

  MILITARY_OWNERSHIP_TYPES = Set.new(['MA', 'MN', 'MR', 'CG'])

  def initialize(airports)
    @airports = airports
    @current_data_cycle = FaaApi.client.current_data_cycle
    @bounding_box_calculator = AirportBoundingBoxCalculator.new
  end

  def load_database
    @airports.each do |airport_code, airport_data|
      airport = update_airport(airport_code, airport_data)

      update_tags(airport)
      update_bounding_box(airport)

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

  def update_airport(airport_code, airport_data)
    airport = Airport.find_by(code: airport_code) || Airport.new

    # Normalize the facility type to the options we use for filtering
    if airport_data[:ownership_type].in?(MILITARY_OWNERSHIP_TYPES)
      airport_data[:facility_type] = :military
    else
      airport_data[:facility_type] = FACILITY_TYPES[airport_data[:facility_type]].to_s
    end

    # rubocop:disable Layout/HashAlignment
    airport.update!({
      code:            airport_code,
      name:            airport_data[:airport_name],
      facility_type:   airport_data[:facility_type],
      facility_use:    airport_data[:facility_use],
      ownership_type:  airport_data[:ownership_type],
      latitude:        airport_data[:latitude],
      longitude:       airport_data[:longitude],
      coordinates:     [airport_data[:latitude], airport_data[:longitude]],
      elevation:       airport_data[:elevation],
      city:            airport_data[:city],
      state:           airport_data[:state],
      city_distance:   airport_data[:city_distance],
      fuel_types:      airport_data[:fuel_types].split(','),
      landing_rights:  (airport_data[:facility_use] == 'PR' ? :private_ : :public_),
      sectional:       airport_data[:sectional],
      activation_date: airport_data[:activation_date],
      faa_data_cycle:  @current_data_cycle,
    })
    # rubocop:enable Layout/HashAlignment

    return airport
  end

  def update_tags(airport)
    # Tag public and private airports
    # Skip military airports as those are all private so there's no need to tag them
    if !airport.ownership_type.in?(MILITARY_OWNERSHIP_TYPES) && airport.tags.where(name: [:private_, :public_]).count == 0
      tag = (airport.facility_use == 'PR' ? :private_ : :public_)
      airport.tags << Tag.new(name: tag)
    end

    # Tag airports without any user contributed data yet
    if airport.empty? && airport.tags.where(name: :empty).count == 0 # rubocop:disable Style/GuardClause
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

  def update_bounding_box(airport)
    # Updating the bounding box involves an API query to OpenStreeMaps. Since the location of an airport doesn't
    # change, only do this if we don't already have a bounding box value for the airport or it was already done and
    # no bounding box was found. Also skip facility types like heliports as they are small enough to simply zoom
    # in on their center.
    return if airport.bbox_checked? || !airport.uses_bounding_box? || airport.has_bounding_box?

    bounding_box = @bounding_box_calculator.calculate(airport)

    airport.update!({
      bbox_checked: true,
      bbox_ne_latitude: bounding_box[:northeast][:latitude],
      bbox_ne_longitude: bounding_box[:northeast][:longitude],
      bbox_sw_latitude: bounding_box[:southwest][:latitude],
      bbox_sw_longitude: bounding_box[:southwest][:longitude],
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
