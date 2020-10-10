class Airport < ApplicationRecord
  has_many :runways
  has_many :remarks

  validates_uniqueness_of :code
  validates_uniqueness_of :site_number

  def self.geojson
    return Airport.select(:name, :code, :latitude, :longitude).map do |airport|
      next {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [airport.longitude, airport.latitude],
        },
        properties: {
          name: airport.name,
          code: airport.code,
        },
      }
    end
  end
end
