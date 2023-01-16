class Tag < ApplicationRecord
  belongs_to :airport

  validates :name, uniqueness: {scope: :airport}
  validates :name, presence: true

  after_save :remove_empty_tag!

  has_paper_trail meta: {airport_id: :airport_id}

  TAGS = {
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
    unmapped: {
      label: 'Unmapped',
      icon: 'map-marked-alt',
      theme: 'blue-grey',
    },
    food: {
      label: 'Food',
      icon: 'hamburger',
      theme: 'deep-orange',
      addable: true,
    },
    camping: {
      label: 'Camping',
      icon: 'campground',
      theme: 'green',
      addable: true,
    },
    lodging: {
      label: 'Lodging',
      icon: 'bed',
      theme: 'brown',
      addable: true,
    },
    car: {
      label: 'Car Rental',
      icon: 'car',
      theme: 'orange',
      addable: true,
    },
    bicycles: {
      label: 'Bicycles',
      icon: 'person-biking',
      theme: 'green',
      addable: true,
    },
    swimming: {
      label: 'Swimming',
      icon: 'umbrella-beach',
      theme: 'blue',
      addable: true,
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      theme: 'orange',
      addable: true,
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      theme: 'light-green',
      addable: true,
    },
    fishing: {
      label: 'Fishing',
      icon: 'fish',
      theme: 'cyan',
      addable: true,
    },
    museum: {
      label: 'Museum',
      icon: 'landmark',
      theme: 'indigo',
      addable: true,
    },
    closed: {
      label: 'Closed',
      icon: 'times-circle',
      theme: 'brown',
    },
    airpark: {
      label: 'Airpark',
      icon: 'home',
      theme: 'orange',
      addable: true,
    },
    empty: {
      label: 'Empty',
      icon: 'question',
      theme: 'pink',
    },
  }

  enum name: TAGS.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  def self.addable_tags
    return TAGS.select {|_key, value| value[:addable]}
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
