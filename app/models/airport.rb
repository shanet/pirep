class Airport < ApplicationRecord
  has_many :runways, dependent: :destroy
  has_many :remarks, dependent: :destroy
  has_many :tags, dependent: :destroy

  validates :code, uniqueness: true
  validates :site_number, uniqueness: true

  FACILITY_TYPES = {
    airport: {
      label: 'Airports',
      icon: 'plane',
      color: 'red',
      default: true,
    },
    heliport: {
      label: 'Heliports',
      icon: 'helicopter',
      color: 'orange',
    },
    seaplane_base: {
      label: 'Seaplane Bases',
      icon: 'water',
      color: 'yellow',
    },
    military: {
      label: 'Military',
      icon: 'crosshairs',
      color: 'green',
    },
    balloonport: {
      hidden: true,
    },
    gliderport: {
      hidden: true,
    },
    ultralight: {
      hidden: true,
    },
  }

  enum facility_type: FACILITY_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  def self.geojson
    return Airport.includes(:tags).map {|airport| airport.to_geojson}
  end

  def self.facility_types
    # Don't show hidden facility types in the UI
    return FACILITY_TYPES.reject {|key, value| value[:hidden]}
  end

  def to_geojson
    return {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [longitude, latitude],
      },
      properties: {
        code: code,
        tags: tags.pluck(:name),
        facility_type: facility_type,
      },
      # Mapbox requires IDs to be integers (even though the RFC says strings are okay!)
      # so we need a hash function that returns a 32bit number. CRC32 should do the job.
      id: Zlib.crc32(code),
    }
  end

  def empty?
    # Return if the airport has some user contributed info filled out for it
    return ![
      :crew_car,
      :description,
      :fuel_location,
      :landing_fees,
      :passport_location,
      :transient_parking,
      :wifi,
    ].map {|column| send(column).present?}.any?
  end
end
