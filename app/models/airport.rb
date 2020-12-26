require 'google/google_api'

class Airport < ApplicationRecord
  has_many :runways, dependent: :destroy
  has_many :remarks, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :comments, dependent: :destroy

  accepts_nested_attributes_for :tags

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

  LANDING_RIGHTS_TYPES = {
    public_: {
      requirements_label: 'Notes:',
      description: 'Open to public',
    },
    restrictions: {
      requirements_label: 'Requirements for landing:',
      description: 'Allowed with restrictions',
    },
    permission: {
      requirements_label: 'Contact info for landing permission:',
      description: 'Allowed with prior permission',
    },
    private_: {
      description: 'Private to everyone :(',
    },
  }

  enum facility_type: FACILITY_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}
  enum landing_rights: LANDING_RIGHTS_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  has_many_attached :photos

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
      id: code_digest,
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

  def private?
    return facility_use == 'PR'
  end

  def landing_rights
    return self[:landing_rights].to_sym
  end

  def all_photos
    return photos.order(created_at: :desc) + GoogleApi.client.place_photos('%s - %s Airport' % [code, name], latitude, longitude)
  end

  def unselected_tag_names
    # Remove already added tags on the airport from the full set of tags
    return (Tag.addable_tags.keys - tags.pluck(:name).map(&:to_sym))
  end

  def theme
    # These match the themes defined in the themes CSS file
    themes = [
      'red',
      'pink',
      'purple',
      'deep-purple',
      'indigo',
      'blue',
      'light-blue',
      'cyan',
      'teal',
      'green',
      'light-green',
      'lime',
      'yellow',
      'amber',
      'orange',
      'deep-orange',
      'brown',
      'blue-grey',
    ]

    return themes[code_digest % themes.count]
  end

  def code_digest
    return Zlib.crc32(code)
  end
end
