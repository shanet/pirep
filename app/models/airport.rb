class Airport < ApplicationRecord
  has_many :runways
  has_many :remarks
  has_many :taggings
  has_many :tags, through: :taggings

  validates_uniqueness_of :code
  validates_uniqueness_of :site_number

  def self.geojson
    # where(facility_type: 'AIRPORT')
    return Airport.includes(:tags).map do |airport|
      next {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [airport.longitude, airport.latitude],
        },
        properties: {
          name: airport.name,
          code: airport.code,
          # tags: airport.tags.pluck(:name),
          tags: ['camping', 'golfing', 'hot springs', 'water', 'helipad', 'seaplane'].sample(3)
        },
      }
    end
  end
end
