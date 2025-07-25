require 'faa/faa_api'

class AirportDatabaseImporter
  def initialize(airports, bounding_box_provider: nil, timezone_provider: nil)
    @airports = airports
    @current_data_cycle = FaaApi.client.current_data_cycle(:airports)
    @bounding_box_provider = bounding_box_provider || AirportBoundingBoxCalculator.new
    @timezone_provider = timezone_provider || AirportTimezoneProvider.new
  end

  def import!
    report = {new: [], closed: []}

    @airports.each_with_index do |(airport_code, airport_data), index|
      # Report back progress to the seeds so progress can be monitored
      yield({total: @airports.count, current: index + 1}) if block_given?

      airport, new_airport = update_airport(airport_code, airport_data)
      next unless airport

      report[:new] << airport[:code] if new_airport

      update_tags(airport)
      update_bounding_box(airport)
      update_timezone(airport)

      (airport_data[:runways] || []).each do |runway|
        update_runway(airport, runway)
      end

      (airport_data[:remarks] || []).each do |remark|
        update_remark(airport, remark)
      end
    end

    report[:closed] = tag_closed_airports.map(&:code).sort
    report[:new].sort!

    return report
  end

private

  def update_airport(airport_code, airport_data)
    airport = Airport.find_by(code: airport_code) || Airport.new
    new_airport = !airport.persisted?

    # Abort anything with conflicting data sources
    if airport.data_source.present? && airport.data_source != airport_data[:data_source].to_s
      Rails.logger.info("Skipping import for #{airport_code} as it has conflicting data sources: #{airport.data_source} / #{airport_data[:data_source]}")
      return nil, nil
    end

    # rubocop:disable Layout/HashAlignment
    airport.update!({
      code:            airport_code,
      name:            airport_data[:airport_name],
      icao_code:       airport_data[:icao_code],
      facility_type:   airport_data[:facility_type],
      facility_use:    airport_data[:facility_use],
      ownership_type:  airport_data[:ownership_type],
      latitude:        airport_data[:latitude],
      longitude:       airport_data[:longitude],
      coordinates:     [airport_data[:longitude], airport_data[:latitude]],
      elevation:       airport_data[:elevation],
      city:            airport_data[:city],
      state:           airport_data[:state],
      country:         airport_data[:country],
      city_distance:   airport_data[:city_distance],
      sectional:       airport_data[:sectional],
      fuel_types:      airport_data[:fuel_types]&.split(','),
      activation_date: airport_data[:activation_date],
      data_source:     airport_data[:data_source],

      # The landing rights are configurable by users so we don't want to overwrite this field unless the airport is first being created
      **(airport.persisted? ? {} : {landing_rights: (airport_data[:facility_use] == 'PR' ? :private_ : :public_)}), # rubocop:disable Style/NestedTernaryOperator
    })
    # rubocop:enable Layout/HashAlignment

    # Update the data cycle without callbacks so the updated_at timestamp won't be updated if there are otherwise no changes to
    # an existing airport as doing so will invalidate the airport info PDFs cache and unnecessarily force an expensive re-render
    airport.update_column(:faa_data_cycle, @current_data_cycle) # rubocop:disable Rails/SkipsModelValidations

    return airport, new_airport
  end

  def update_tags(airport)
    # Tag public and private airports
    # Skip military airports as those are all private so there's no need to tag them
    if !airport.facility_type == :military && airport.tags.where(name: [:private_, :public_, :restricted]).none?
      tag = (airport.facility_use == 'PR' ? :private_ : :public_)
      airport.tags << Tag.new(name: tag)
    end

    # Tag airports without any user contributed data yet
    if airport.empty? && airport.tags.where(name: :empty).none? # rubocop:disable Style/GuardClause
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

    Rails.logger.info("Looking up bounding box for #{airport.id}")
    bounding_box = @bounding_box_provider.calculate(airport)

    airport.update!({
      bbox_checked: true,
      bbox_ne_latitude: bounding_box[:northeast][:latitude],
      bbox_ne_longitude: bounding_box[:northeast][:longitude],
      bbox_sw_latitude: bounding_box[:southwest][:latitude],
      bbox_sw_longitude: bounding_box[:southwest][:longitude],
    })
  end

  def update_timezone(airport)
    return if airport.timezone_checked_at

    Rails.logger.info("Looking up timezone for #{airport.id}")
    timezone = @timezone_provider.timezone(airport)
    airport.update!(timezone: timezone, timezone_checked_at: Time.zone.now)
  end

  def tag_closed_airports
    # This function saddens me to write, but it's interesting data to track airports have closed.
    # We can do this by checking which airports have their data cycle not set to the current one which
    # would denote it had been removed from the FAA's database. This will serve as roughly the date it
    # was closed and we can then add a closed tag to it for display on the map.
    closed_airports = Airport.where(faa_data_cycle: ...@current_data_cycle)
      .where("NOT EXISTS (#{Tag.select('1').where(name: :closed).where('tags.airport_id = airports.id').to_sql})")

    closed_airports.each do |airport|
      Tag.create!(name: :closed, airport: airport)
    end

    return closed_airports
  end
end
