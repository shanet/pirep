class Haversine
  EARTH_RADIUS = 6371 # kilometers

  def distance(latitude1, longitude1, latitude2, longitude2)
    return nil if nil.in?([latitude1, longitude1, latitude2, longitude2])

    latitude1, longitude1, latitude2, longitude2 = to_radians(latitude1, longitude1, latitude2, longitude2)

    delta_latitude = latitude2 - latitude1
    delta_longitude = longitude2 - longitude1

    a = (Math.sin(delta_latitude / 2)**2) + (Math.cos(latitude1) * Math.cos(latitude2) * Math.sin(delta_longitude / 2) * Math.sin(delta_longitude / 2))
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    return EARTH_RADIUS * c * 1000 # meters
  end

private

  def to_radians(*args)
    return args.map {|value| value * Math::PI / 180}
  end
end
