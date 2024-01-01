class Metar < WeatherReport
  validates :flight_category, presence: true
  validates :observed_at, presence: true

  def self.model_name
    return superclass.model_name
  end

  def dewpoint
    return celsius_to_fahrenheit(self[:dewpoint])
  end

  def temperature
    return celsius_to_fahrenheit(self[:temperature])
  end

  def vfr?
    return flight_category.in?(['VFR', 'MVFR'])
  end

  def ifr?
    return flight_category.in?(['IFR', 'LIFR'])
  end

  def mvfr?
    return flight_category == 'MVFR'
  end
end
