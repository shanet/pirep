class Tag < ApplicationRecord
  has_many :taggings
  has_many :airports, through: :taggings

  TAGS = {
    camping: {
      label: 'Camping',
      icon: 'campground',
      color: 'green',
      default: true,
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      color: 'blue',
      default: true,
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      color: 'red',
      default: true,
    },
    water: {
      label: 'Water',
      icon: 'umbrella-beach',
      color: 'yellow',
      default: true,
    },
    helipad: {
      label: 'Helipads',
      icon: 'helicopter',
      color: 'purple',
      default: false,
    },
    seaplane: {
      label: 'Seaplane',
      icon: 'water',
      color: 'pink',
      default: false,
    },
    # private: {
    #   label: 'Private',
    #   icon: 'lock',
    #   color: '',
    # },
  }

  enum name: Tag::TAGS.reduce({}) {|hash, (key, _value)| hash[key] = key.to_s; hash}
end
