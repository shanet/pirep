class Tag < ApplicationRecord
  belongs_to :airport

  validates_uniqueness_of :name, scope: :airport
  validates :airport, presence: true
  validates :name, presence: true

  TAGS = {
    food: {
      label: 'Food',
      icon: 'hamburger',
      color: 'pink',
      addable: true,
    },
    camping: {
      label: 'Camping',
      icon: 'campground',
      color: 'red',
      addable: true,
    },
    golfing: {
      label: 'Golfing',
      icon: 'golf-ball',
      color: 'orange',
      addable: true,
    },
    hot_springs: {
      label: 'Hot Springs',
      icon: 'hot-tub',
      color: 'yellow',
      addable: true,
    },
    water: {
      label: 'Water',
      icon: 'umbrella-beach',
      color: 'green',
      addable: true,
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

  def self.addable_tags
    return TAGS.select {|key, value| value[:addable]}
  end
end
