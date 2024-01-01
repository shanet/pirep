class Taf < WeatherReport
  validates :ends_at, presence: true
  validates :starts_at, presence: true

  def self.model_name
    return superclass.model_name
  end
end
