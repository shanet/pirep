require 'google/google_api'

class Airport < ApplicationRecord
  has_many :runways, dependent: :destroy
  has_many :remarks, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :comments, dependent: :destroy

  accepts_nested_attributes_for :tags

  validates :code, uniqueness: true
  validates :site_number, uniqueness: true

  after_save :remove_empty_tag!

  FACILITY_TYPES = {
    airport: {
      label: 'Airports',
      icon: 'plane',
      theme: 'green',
      default: true,
    },
    heliport: {
      label: 'Heliports',
      icon: 'helicopter',
      theme: 'orange',
    },
    seaplane_base: {
      label: 'Seaplane Bases',
      icon: 'water',
      theme: 'blue',
    },
    military: {
      label: 'Military',
      icon: 'crosshairs',
      theme: 'red',
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
      short_requirements_label: 'Landing Notes',
      long_requirements_label: 'Notes',
      short_description: 'Open to public',
      long_description: 'Open to public',
      color: 'green',
      icon: 'lock-open',
    },
    restrictions: {
      short_requirements_label: 'Restrictions',
      long_requirements_label: 'Requirements for landing',
      short_description: 'Allowed with restrictions',
      long_description: 'Private, but open to public with restrictions',
      color: 'orange',
      icon: 'key',
    },
    permission: {
      short_requirements_label: 'Contact info',
      long_requirements_label: 'Contact info for landing permission (this will be public!)',
      short_description: 'Allowed with prior permission',
      long_description: 'Private, but landing allowed with prior permission',
      color: 'orange',
      icon: 'key',
    },
    private_: {
      short_description: 'Private to everyone',
      long_description: 'Private to everyone <i class="far fa-frown-open"></i>'.html_safe,
      color: 'red',
      icon: 'lock',
    },
  }

  enum facility_type: FACILITY_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}
  enum landing_rights: LANDING_RIGHTS_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  has_many_attached :photos

  def self.geojson
    return Airport.includes(:tags).map(&:to_geojson)
  end

  def self.facility_types
    # Don't show hidden facility types in the UI
    return FACILITY_TYPES.reject {|_key, value| value[:hidden]}
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
    # Return if the airport is tagged with a user-addable tag
    return false if tags.map {|tag| Tag::TAGS[tag.name][:addable]}.any?

    # Return if landing rights/requirements are set
    return false if [:restrictions, :permission].include?(landing_rights) || landing_requirements.present?

    # Return if the airport has some user contributed info filled out for it
    return [
      :crew_car,
      :description,
      :fuel_location,
      :landing_fees,
      :transient_parking,
      :wifi,
    ].map {|column| send(column).present?}.none?
  end

  def remove_empty_tag!
    # Remove the empty tag if the airport is no longer empty
    return if empty?

    tags.where(name: :empty).destroy_all
  end

  def private?
    return facility_use == 'PR'
  end

  def landing_rights
    return self[:landing_rights].to_sym
  end

  def all_photos
    return @all_photos ||= photos.order(created_at: :desc) + GoogleApi.client.place_photos('%s - %s Airport' % [code, name], latitude, longitude)
  end

  def unselected_tag_names
    # Remove already added tags on the airport from the full set of tags
    return (Tag.addable_tags.keys - tags.pluck(:name).map(&:to_sym))
  end

  def elevation_threat_level
    case elevation
      when -Float::INFINITY..2999
        return 'green'
      when 3000..4999
        return 'orange'
      when 5000..Float::INFINITY
        return 'red'
      else # rubocop:disable Lint/DuplicateBranch
        return 'green'
    end
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
