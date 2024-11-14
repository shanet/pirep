class Tag < ApplicationRecord
  belongs_to :airport

  has_many :actions, as: :actionable, dependent: :nullify

  validates :name, uniqueness: {scope: :airport}
  validates :name, presence: true

  after_save :remove_empty_tag!

  has_paper_trail meta: {airport_id: :airport_id}

  TAGS = {
    populated: {
      label: 'Documented',
      icon: 'book',
      theme: 'green',
      default: true,
    },
    empty: {
      label: 'Undocu&shy;mented'.html_safe,
      icon: 'question',
      theme: 'pink',
    },
    public_: {
      label: 'Public',
      icon: 'lock-open',
      theme: 'green',
    },
    private_: {
      label: 'Private',
      icon: 'lock',
      theme: 'red',
    },
    restricted: {
      label: 'Restricted',
      icon: 'key',
      theme: 'orange',
    },
    unmapped: {
      label: 'Unmapped',
      icon: 'map-marked-alt',
      theme: 'blue-grey',
      searchable: true,
    },
    events: {
      label: 'Events',
      icon: 'calendar-days',
      theme: 'light-blue',
      searchable: true,
      origin: true,
      scroll_target: 'events',
    },
    food: {
      label: 'Food',
      icon: 'hamburger',
      theme: 'deep-orange',
      addable: true,
      searchable: true,
      origin: true,
    },
    camping: {
      label: 'Camping',
      icon: 'campground',
      theme: 'green',
      addable: true,
      searchable: true,
      origin: true,
    },
    lodging: {
      label: 'Lodging',
      icon: 'bed',
      theme: 'brown',
      addable: true,
      searchable: true,
      origin: true,
    },
    car: {
      label: 'Car Rental',
      icon: 'car',
      theme: 'orange',
      addable: true,
      searchable: true,
      scroll_target: 'crew-car',
      origin: true,
    },
    bicycles: {
      label: 'Bicycles',
      icon: 'person-biking',
      theme: 'green',
      addable: true,
      searchable: true,
      origin: true,
    },
    swimming: {
      label: 'Swimming',
      icon: 'umbrella-beach',
      theme: 'blue',
      addable: true,
      searchable: true,
      origin: true,
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      theme: 'light-green',
      addable: true,
      searchable: true,
      origin: true,
    },
    fishing: {
      label: 'Fishing',
      icon: 'fish',
      theme: 'cyan',
      addable: true,
      searchable: true,
      origin: true,
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      theme: 'orange',
      addable: true,
      searchable: true,
    },
    museum: {
      label: 'Museum',
      icon: 'landmark',
      theme: 'indigo',
      addable: true,
      searchable: true,
    },
    flying_clubs: {
      label: 'Flying Clubs',
      icon: 'people-group',
      theme: 'deep-orange',
      addable: true,
      searchable: true,
      scroll_target: 'flying-clubs',
    },
    weather_report: {
      label: 'METAR / TAF',
      icon: 'cloud-sun',
      theme: 'lime',
      searchable: true,
      scroll_target: 'weather-reports',
    },
    webcam: {
      label: 'Webcam',
      icon: 'camera',
      theme: 'purple',
      searchable: true,
      scroll_target: 'webcams',
    },
    airpark: {
      label: 'Airpark',
      icon: 'home',
      theme: 'orange',
      addable: true,
      searchable: true,
    },
    closed: {
      label: 'Closed',
      icon: 'times-circle',
      theme: 'brown',
      searchable: true,
    },
  }

  enum :name, TAGS.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  # Tags addable to an airport by a user
  def self.addable_tags
    return TAGS.select {|_key, value| value[:addable]}
  end

  # Tags that are used in the filters on the origin info modal
  def self.origin_tags
    return TAGS.select {|_key, value| value[:origin]}
  end

  def name
    return self[:name].to_sym
  end

  def label
    return TAGS[name]&.[](:label)
  end

private

  def remove_empty_tag!
    airport.remove_empty_tag!
  end
end
