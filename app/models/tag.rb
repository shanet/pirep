class Tag < ApplicationRecord
  belongs_to :airport

  validates_uniqueness_of :name, scope: :airport
  validates :airport, presence: true
  validates :name, presence: true

  TAGS = {
    food: {
      label: 'Food',
      icon: 'hamburger',
      theme: 'red',
      addable: true,
    },
    camping: {
      label: 'Camping',
      icon: 'campground',
      theme: 'green',
      addable: true,
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      theme: 'light-green',
      addable: true,
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      theme: 'orange',
      addable: true,
    },
    lodging: {
      label: 'Lodging',
      icon: 'bed',
      theme: 'brown',
      addable: true,
    },
    water: {
      label: 'Water',
      icon: 'umbrella-beach',
      theme: 'blue',
      addable: true,
    },
    public_: {
      label: 'Public',
      icon: 'lock-open',
      theme: 'teal',
    },
    private_: {
      label: 'Private',
      icon: 'lock',
      theme: 'deep-orange',
    },
    unmapped: {
      label: 'Unmapped',
      icon: 'map-marked-alt',
      theme: 'blue-grey',
    },
    closed: {
      label: 'Closed',
      icon: 'times-circle',
      theme: 'brown',
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
    empty: {
      label: 'Empty',
      icon: 'question',
      theme: 'pink',
    },
  }

  enum name: TAGS.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}

  def self.addable_tags
    return TAGS.select {|key, value| value[:addable]}
  end
end
