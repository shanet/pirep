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
      {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [airport.longitude, airport.latitude],
        },
        properties: {
          code: airport.code,
          #tags: airport.tags.pluck(:name),
          tags: Tag::TAGS.keys.sample(3),
        },
        # Mapbox requires IDs to be integers (even though the RFC says strings are okay!)
        # so we need a hash function that returns a 32bit number. CRC32 should do the job.
        id: Zlib.crc32(airport.code),
      }
    end
  end
end
