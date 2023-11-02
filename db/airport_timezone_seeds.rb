class AirportTimezoneSeeds
  def initialize
    @timezones = YAML.safe_load(Rails.root.join('db/fixtures/airport_timezones.yml').read)
  end

  def timezone(airport)
    return @timezones[airport.code]
  end
end
