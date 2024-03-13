require 'exceptions'

class AirportSearcher
  def initialize(filters)
    @airport_from = filters[:airport_from]&.upcase
    @distance_from = filters[:distance_from].to_i

    @elevation = filters[:elevation].to_i
    @events_threshold = filters[:events_threshold].to_i

    @runway_length = filters[:runway_length].to_i
    @runway_lighted = filters[:runway_lighted]
    @runway_paved = filters[:runway_paved]
    @runway_grass = filters[:runway_grass]

    @access_public = filters[:access_public]
    @access_restricted = filters[:access_restricted]
    @access_private = filters[:access_private]

    @facility_airport = filters[:facility_airport]
    @facility_heliport = filters[:facility_heliport]
    @facility_seaplane_base = filters[:facility_seaplane_base]
    @facility_military = filters[:facility_military]

    @weather_vfr = filters[:weather_vfr]
    @weather_mvfr = filters[:weather_mvfr]
    @weather_ifr = filters[:weather_ifr]
    @weather_lifr = filters[:weather_lifr]

    @tags_match = filters[:tags_match]
    @tags = filters.each.select {|key, value| key.start_with?('tag_') && value == '1'}.map {|filter| filter.first.gsub(/^tag_/, '')}
  end

  def results
    return nil if empty?

    query = Airport

    query = location_filter(query)
    query = access_filter(query)
    query = tag_filter(query)
    query = elevation_filter(query)
    query = runway_filter(query)
    query = weather_filter(query)
    query = facility_filter(query)
    query = events_filter(query)

    # Group by ID to remove any duplicate rows
    return query.group(:id)
  end

  def empty?
    return !(
      @airport_from.presence ||
      @distance_from > 0 ||

      @elevation > 0 ||
      @events_threshold > 0 ||

      @runway_length > 0 ||
      @runway_lighted ||
      @runway_paved ||
      @runway_grass ||

      @access_public ||
      @access_restricted ||
      @access_private ||

      @facility_airport ||
      @facility_heliport ||
      @facility_seaplane_base ||
      @facility_military ||

      @weather_vfr ||
      @weather_mvfr ||
      @weather_ifr ||
      @weather_lifr ||

      @tags.any?
    )
  end

private

  def location_filter(query)
    # Ensure that if one of the values is present then the other is as well
    raise Exceptions::IncompleteLocationFilter if @airport_from.present? ^ (@distance_from > 0)

    # But it's okay if both are omitted
    return query unless @airport_from.presence && @distance_from

    airport = Airport.find_by(code: @airport_from) || Airport.find_by(icao_code: @airport_from)
    raise Exceptions::AirportNotFound unless airport

    # Filter by distance and then order by distance
    query = query.where('coordinates <@> point(?,?) <= ?', airport.latitude, airport.longitude, @distance_from)
    return query.order(Arel.sql(ApplicationRecord.sanitize_sql_array(['coordinates <@> point(?,?)', airport.latitude, airport.longitude])))
  end

  def access_filter(query)
    landing_rights = []
    landing_rights << :public_ if @access_public
    landing_rights << :restricted if @access_restricted
    landing_rights << :private_ if @access_private

    return query if landing_rights.empty?

    return query.where(landing_rights: landing_rights)
  end

  def tag_filter(query)
    return query if @tags.empty?

    if @tags_match == 'or'
      return query.joins(:tags).where(tags: {name: @tags})
    end

    return query.where(id: Airport.select(:id).group(:id).joins(:tags).where(tags: {name: @tags}).having("COUNT(DISTINCT #{Tag.table_name}.name) = ?", @tags.size))
  end

  def elevation_filter(query)
    return query unless @elevation > 0

    return query.where('elevation < ?', @elevation)
  end

  def runway_filter(query)
    query = query.joins(:runways).where('runways.length >= ?', @runway_length) if @runway_length > 0
    query = query.joins(:runways).where.not(runways: {lights: ''}) if @runway_lighted
    query = query.joins(:runways).where(runways: {surface: ['ASPH', 'ASPH-CONC', 'CONC', 'METAL', 'STEEL']}) if @runway_paved
    query = query.joins(:runways).where(runways: {surface: ['TURF', 'DIRT', 'GRAVEL', 'SNOW', 'ICE', 'TREATED', 'GRASS', 'SAND', 'WOOD']}) if @runway_grass

    return query
  end

  def weather_filter(query)
    flight_categories = []
    flight_categories << 'VFR' if @weather_vfr
    flight_categories << 'MVFR' if @weather_mvfr
    flight_categories << 'IFR' if @weather_ifr
    flight_categories << 'LIFR' if @weather_lifr

    return query if flight_categories.empty?

    return query.joins(:metar).where(metar: {flight_category: flight_categories})
  end

  def facility_filter(query)
    facility_types = []
    facility_types << :airport if @facility_airport
    facility_types << :heliport if @facility_heliport
    facility_types << :seaplane_base if @facility_seaplane_base
    facility_types << :military if @facility_military

    # Only show airports if nothing else was selected since the other types are rarely desired in search results
    facility_types << :airport if facility_types.empty?

    return query.where(facility_type: facility_types)
  end

  def events_filter(query)
    return query unless @events_threshold > 0

    return query.joins(:events).where('events.start_date <= ?', @events_threshold.days.from_now)
  end
end