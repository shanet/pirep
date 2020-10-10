class AirportImporter
  def initialize(airports)
    @airports = airports
  end

  def load_database
    @airports.each do |site_number, airport_data|
      airport = update_airport(airport, site_number, airport_data)

      (airport_data[:runways] || []).each do |runway|
        update_runway(airport, runway)
      end

      (airport_data[:remarks] || []).each do |remark|
        update_remark(airport, remark)
      end
    end
  end

private

  def update_airport(airport, site_number, airport_data)
    airport = Airport.find_by(site_number: site_number) || Airport.new(site_number: site_number)

    airport.update!({
      code: airport_data[:airport_code],
      name: airport_data[:airport_name],
      facility_type: airport_data[:facility_type],
      facility_use: airport_data[:facility_use],
      ownership_type: airport_data[:ownership_type],
      owner_name: airport_data[:owner_name],
      owner_phone: airport_data[:owner_phone],
      latitude: airport_data[:latitude],
      longitude: airport_data[:longitude],
      elevation: airport_data[:elevation],
      fuel: airport_data[:fuel],
    })

    return airport
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
end
