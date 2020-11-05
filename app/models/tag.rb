class Tag < ApplicationRecord
  belongs_to :airport

  validates_uniqueness_of :name, scope: :airport
  validates :airport, presence: true
  validates :name, presence: true

  TAGS = {
    camping: {
      label: 'Camping',
      icon: 'campground',
      color: 'red',
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      color: 'orange',
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      color: 'yellow',
    },
    water: {
      label: 'Water',
      icon: 'umbrella-beach',
      color: 'green',
    },
    public_: {
      label: 'Public',
      icon: 'lock-open',
      color: 'blue',
    },
    private_: {
      label: 'Private',
      icon: 'lock',
      color: 'purple',
    },
    empty: {
      label: 'Empty',
      icon: 'question',
      color: 'brown',
    },
  }

  enum name: TAGS.each_with_object({}) {|(key, _value), hash| hash[key] = key.to_s;}
end
