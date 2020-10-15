class Airport < ApplicationRecord
  has_many :runways, dependent: :destroy
  has_many :remarks, dependent: :destroy
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  validates :code, uniqueness: true
  validates :site_number, uniqueness: true

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
          tags: ['camping', 'golfing', 'hot springs', 'water', 'helipad', 'seaplane'].sample(3),
        },
      }
    end
  end
end
