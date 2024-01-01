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

  def ceiling
    return SKY_CLEAR if cloud_layers.empty? || cloud_layers.first['coverage'] == 'CLR'

    ceilings = cloud_layers.select {|cloud_layer| cloud_layer['coverage'].in?(CEILINGS)}

    return (ceilings.any? ? ceilings.first['altitude'] : SKY_CLEAR)
  end

private

  def celsius_to_fahrenheit(value)
    return nil unless value

    return (value * 9 / 5.to_f) + 32
  end
end
