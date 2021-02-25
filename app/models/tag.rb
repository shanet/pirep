class Tag < ApplicationRecord
  belongs_to :airport

  validates_uniqueness_of :name, scope: :airport
  validates :airport, presence: true
  validates :name, presence: true

  after_save :remove_empty_tag!

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
    lodging: {
      label: 'Lodging',
      icon: 'bed',
      theme: 'brown',
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
    unmapped: {
      label: 'Unmapped',
      icon: 'map-marked-alt',
      theme: 'blue-grey',
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
    closed: {
      label: 'Closed',
      icon: 'times-circle',
      theme: 'brown',
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

private

  def remove_empty_tag!
    airport.remove_empty_tag!
  end
end
