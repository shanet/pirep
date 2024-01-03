class WeatherReport < ApplicationRecord
  belongs_to :airport

  CLOUD_COVERAGE = {
    'FEW' => 'Few',
    'SCT' => 'Scattered',
    'BKN' => 'Broken',
    'OVC' => 'Overcast',
    'OVX' => 'Obscured',
  }

  # "Few" and "scattered" are not ceilings
  CEILINGS = ['BKN', 'OVC', 'OVX']

  SKY_CLEAR = -1
  WINDS_VARIABLE = -1

  validates :raw, presence: true

  after_create :add_airport_tag
  after_destroy :remove_airport_tag

  def ceiling
    return SKY_CLEAR if cloud_layers.empty? || cloud_layers.first['coverage'] == 'CLR'

    ceilings = cloud_layers.select {|cloud_layer| cloud_layer['coverage'].in?(CEILINGS)}

    return (ceilings.any? ? ceilings.first['altitude'] : SKY_CLEAR)
  end

private

  def add_airport_tag
    # Don't add another tag if one already exists
    return if airport.tags.where(name: :weather_report).any?

    airport.tags << Tag.new(name: :weather_report)
  end

  def remove_airport_tag
    # Only remove the tag when the airport has no METAR or TAFs
    return if airport.metar || airport.tafs.any?

    airport.tags.where(name: :weather_report).destroy_all
  end

  def celsius_to_fahrenheit(value)
    return nil unless value

    return (value * 9 / 5.to_f) + 32
  end
end
