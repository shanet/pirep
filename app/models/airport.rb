require 'google/google_api'

class Airport < ApplicationRecord
  include AttachmentOrganizable
  include Searchable

  has_many :runways, dependent: :destroy
  has_many :remarks, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :actions, as: :actionable, dependent: :destroy

  belongs_to :featured_photo, class_name: 'ActiveStorage::Attachment', optional: true
  has_many_attached_with :contributed_photos, path: -> {"uploads/airport_photos/contributed/#{code.downcase}"}
  has_many_attached_with :external_photos, path: -> {"uploads/airport_photos/external/#{code.downcase}"}

  accepts_nested_attributes_for :tags

  # Rank airport codes above names to prioritize searching by airport code
  # Also rank public airports over private airports
  searchable({column: :code, weight: ['facility_use = \'PU\'', :A, :B]})
  searchable({column: :name, weight: ['facility_use = \'PU\'', :C, :D]})

  # Only run version collation after an update if one of the columns we create versions for was changed (airport database updates are much faster without these running)
  after_update :collate_versions!, if: proc {HISTORY_COLUMNS.keys.select {|column| send("#{column}_changed?")}.any?}
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
      label: 'Military Bases',
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

  FACILITY_USES = {
    PU: 'Public',
    PR: 'Private',
  }

  OWNERSHIP_TYPES = {
    PU: 'Public',
    PR: 'Private',
    MA: 'Air Force',
    MN: 'Navy',
    MR: 'Army',
    CG: 'Coast Guard',
  }

  LANDING_RIGHTS_TYPES = {
    public_: {
      short_description: 'Open to the public',
      long_description: 'Open to the public',
      color: 'green',
      icon: 'lock-open',
      button: 'success',
    },
    restricted: {
      has_requirements: true,
      short_requirements_label: 'Restricted',
      long_requirements_label: 'Requirements/contact info for landing',
      short_description: 'Allowed with restrictions/permission',
      long_description: 'Private, but open to public with restrictions',
      color: 'orange',
      icon: 'key',
      button: 'warning',
    },
    private_: {
      short_description: 'Private to everyone',
      long_description: 'Private to everyone <i class="far fa-frown-open"></i>'.html_safe,
      color: 'red',
      icon: 'lock',
      button: 'danger',
    },
  }

  COVER_IMAGES = {
    default: 'Default',
    beach: 'Beach',
    city: 'City',
    desert: 'Desert',
    forest: 'Forest',
    mountains: 'Mountains',
    town: 'Town',
  }

  # These columns are editable via shared textareas and require conflict resolution to avoid overwriting changes
  TEXTAREA_EDITABLE_COLUMNS = {
    description: 'Description',
    transient_parking: 'Transient Parking',
    fuel_location: 'Fuel location',
    landing_fees: 'Landing Fees',
    crew_car: 'Crew Car',
    wifi: 'WiFi',
  }

  # Only keep versions for changes to these columns
  HISTORY_COLUMNS = {
    landing_rights: 'Landing rights',
    landing_requirements: 'Landing requirements',
    cover_image: 'Theme',
    annotations: 'Annotations',
  }.merge(TEXTAREA_EDITABLE_COLUMNS)

  # Only create versions when there's a change to one of the columns listed above
  has_paper_trail only: self::HISTORY_COLUMNS.keys

  enum facility_type: FACILITY_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}
  enum landing_rights: LANDING_RIGHTS_TYPES.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  validates :code, uniqueness: true, presence: true
  validates :name, presence: true
  validates :latitude, numericality: {}
  validates :longitude, numericality: {}
  validates :elevation, numericality: {only_integer: true}
  validates :facility_type, inclusion: {in: FACILITY_TYPES.keys.map(&:to_s)}
  validates :facility_use, inclusion: {in: FACILITY_USES.keys.map(&:to_s)}
  validates :ownership_type, inclusion: {in: OWNERSHIP_TYPES.keys.map(&:to_s)}
  validates :cover_image, inclusion: {in: COVER_IMAGES.keys.map(&:to_s)}
  validates :state, length: {is: 2}, if: -> {state.present?}
  validate :contributed_photos_size_and_filetype

  def self.geojson
    return Airport.includes(:tags).map(&:to_geojson)
  end

  def self.facility_types
    # Don't show hidden facility types in the UI
    return FACILITY_TYPES.reject {|_key, value| value[:hidden]}
  end

  def self.new_unmapped(parameters)
    # State is not part of the airport model so remove it and store it for the code below below passing the parameters to the new record
    state = parameters[:state]
    parameters.delete(:state)

    airport = Airport.new(parameters)

    # We need to generate some unique code for the airport. By definition, an unmapped airport won't have a code so give it a fake letter
    # prefix (with three letters so it doesn't conflict with any future ICAO codes) and an sequentially increasing number suffix to make
    # it unique. There may be a better way to do this but this should be sufficient for now. It's not likely that we'll have a bunch of
    # unmapped airports that would make this number suffix huge.
    airport.code = "UNM#{(Airport.joins(:tags).where('tags.name': :unmapped).count + 1).to_s.rjust(2, '0')}"
    airport.facility_use = :PR
    airport.facility_type = :airport
    airport.ownership_type = :PR
    airport.landing_rights ||= :private_
    airport.tags << Tag.new(name: :unmapped)

    # All unmapped airports must be privately owned. If it was publicly owned it would be listed in the FAA database.
    airport.tags << Tag.new(name: :private_)

    # Tag closed airports as closed
    airport.tags << Tag.new(name: :closed) if state == 'closed'

    return airport
  end

  def []=(key, value)
    # Papertrail will not deserialize point objects from JSONB as point objects.
    # Convert `coordinates` to a point object when deserializing to account for this.
    if key == :coordinates && value.is_a?(Hash)
      value = ActiveRecord::Point.new(value['x'], value['y'])
    end

    super
  end

  def annotations=(value)
    # Patch requests will send the annotations as a string so we need to parse it for it to be properly saved as a JSONB object
    value = JSON.parse(value) if value.is_a?(String)
    super
  end

  def fuel_types=(value)
    # Split CSV strings into arrays for any fuel types that are submitted from a form textfield as such
    value = value.split(',').map(&:strip) if value.is_a?(String)
    super
  end

  def to_geojson
    return {
      # Mapbox requires IDs to be integers (even though the RFC says strings are okay!)
      # so we need a hash function that returns a 32bit number. CRC32 should do the job.
      id: code_digest,
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
    }
  end

  def empty?
    # Return if the airport is tagged with a user-addable tag
    return false if tags.map {|tag| Tag::TAGS[tag.name][:addable]}.any?

    # Return if landing rights/requirements are set
    return false if [:restricted, :permission].include?(landing_rights) || landing_requirements.present?

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

  def collate_versions!
    VersionsCollatorJob.perform_later(self)
  end

  def closed?
    return tags.where(name: :closed).count > 0
  end

  def unmapped?
    return tags.where(name: :unmapped).count > 0
  end

  def private?
    return facility_use == 'PR'
  end

  def has_bounding_box? # rubocop:disable Naming/PredicateName
    return uses_bounding_box? && bbox_ne_latitude.present?
  end

  def uses_bounding_box?
    # Heliports and seaplane bases are small enough to simply zoom in on their center rather than calculating a bounding box
    return ['heliport', 'seaplane_base'].exclude?(facility_type)
  end

  def bounding_box
    return (has_bounding_box? ? [[bbox_sw_longitude, bbox_sw_latitude], [bbox_ne_longitude, bbox_ne_latitude]] : nil)
  end

  def zoom_level
    return (uses_bounding_box? ? 16 : 17)
  end

  def landing_rights
    return self[:landing_rights]&.to_sym
  end

  def attach_contributed_photos(photos)
    # Before attaching images downsize them, normalize to JPG, and strip EXIF data. To save on storage costs we ideally
    # don't want/need to be storing large source images that are never displayed. Using Rails' ActiveStorage variants it
    # will store the source images as well as make it extremely difficult to control the S3 keys and be served through
    # the CDN. Preprocessing the images before attaching them avoids all of these problems.
    photos.each do |photo|
      source = "#{photo.tempfile.path}_src"
      FileUtils.cp(photo.tempfile.path, source)

      ImageProcessing::Vips.source(source)
        .resize_to_limit(1500, 1500)
        .convert('jpg')
        .saver(strip: true, quality: 80)
        .call(destination: photo.tempfile.path)
    end

    return contributed_photos.attach(photos)
  end

  def all_photos
    return {
      featured: [featured_photo].compact,
      contributed: (contributed_photos.attachments.is_a?(Array) ? reload.contributed_photos : contributed_photos).order(created_at: :desc),
      external: external_photos.order(created_at: :asc),
    }
  end

  def featured_photo
    # If there was an error uploading a new photo and the airport page is being displayed again contributed photos will be
    # an array. However, we want the collection proxy object to query against so perform a reload to get this object instead.
    return (contributed_photos.attachments.is_a?(Array) ? reload.contributed_photos : contributed_photos).find_by(id: featured_photo_id) || external_photos.find_by(id: featured_photo_id)
  end

  def featured_photo=(photo)
    self[:featured_photo_id] = photo&.id
  end

  def uncached_external_photos(force_update: false)
    return nil if external_photos_updated_at && !force_update

    Rails.logger.info("Updating external photos cache for #{code}")
    photos = GoogleApi.client.place_photos("#{code} - #{name} Airport", latitude, longitude)
    AirportPhotosCacherJob.perform_later(self, photos)
    return photos
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

  def all_versions
    # Return versions of the airport and associated tags as well
    return versions.or(PaperTrail::Version.where(item_type: 'Tag', airport_id: id)).reorder(created_at: :desc)
  end

  def created_by
    return Users::User.find_by(id: versions.find_by(event: 'create')&.whodunnit)
  end

  def contributed_photos_size_and_filetype
    contributed_photos.each do |photo|
      if photo.blob.byte_size > 5.megabytes
        errors.add(:contributed_photos, 'must be under 5mb in size')
      end

      unless photo.content_type.in?(['image/jpeg', 'image/png'])
        errors.add(:contributed_photos, 'must a JPG or PNG file')
      end
    end
  end
end
