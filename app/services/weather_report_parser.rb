class WeatherReportParser
  def initialize(report)
    @report = report
  end

  def weather_label
    return '' if @report&.weather.blank?

    return @report.weather.split.map do |condition|
      prefix = nil
      suffix = nil

      if condition[0].in?(['+', '-'])
        prefix = (condition[0] == '+' ? 'heavy' : 'light')
        condition = condition[1..]
      end

      if condition[0..1] == 'VC'
        suffix = 'in vicinity'
        condition = condition[2..]
      end

      descriptor = {
        'MI' => 'shallow',
        'PR' => 'partial',
        'BC' => 'patches',
        'DR' => 'low drifting',
        'BL' => 'blowing',
        'SH' => 'showers',
        'TS' => 'thunderstorm',
        'FZ' => 'freezing',
      }[condition[0..1]]

      # Drop the two characters if there was a amtch
      condition = condition[2..] if descriptor

      phenomena = {
        'DZ' => 'drizzle',
        'RA' => 'rain',
        'SN' => 'snow',
        'SG' => 'snow grains',
        'IC' => 'ice crystals',
        'PL' => 'ice pellets',
        'GR' => 'hail',
        'GS' => 'snow pellets',
        'UP' => 'unknown precipitation',

        'BR' => 'mist',
        'FG' => 'fog',
        'FU' => 'smoke',
        'VA' => 'volcanic ash',
        'DU' => 'widespread dust',
        'SA' => 'sand',
        'HZ' => 'haze',
        'PY' => 'spray',

        'PO' => 'sand whirls',
        'SQ' => 'squalls',
        'FC' => 'tornado',
        'SS' => 'sandstorm',
      }[condition[0..1]]

      # These two should be flipped so the phrase reads correctly
      next [prefix, phenomena, descriptor, suffix].compact.join(' ') if descriptor.in?(['showers', 'patches'])

      next [prefix, descriptor, phenomena, suffix].compact.join(' ')
    end.join(', ')
  end

  def weather_category
    return nil if @report&.weather.blank?

    # Only consider the first weather condition for the overall category
    condition = @report.weather.split.first

    # Remove the prefix if it exists as it doesn't matter for this
    condition = condition[1..] if condition[0].in?(['+', '-'])

    # The only descriptors we care about are thunderstorms and freezing precipitation. Otherwise, drop the descriptor.
    if condition.length == 4
      case condition[0..1]
        when 'TS'
          return :thunderstorm
        when 'FZ'
          return :freezing
      end

      condition = condition[2..]
    end

    case condition[0..1]
      when 'DZ', 'RA', 'BR'
        return :rain
      when 'SN', 'SG'
        return :snow
      when 'IC', 'PL', 'GS'
        return :freezing
      when 'FG'
        return :cloud
      when 'FU', 'DU', 'SA', 'HZ'
        return :smoke
      when 'VA'
        return :volcano
      when 'PO', 'SQ'
        return :wind
      when 'FC', 'SS'
        return :tornado
    end

    return nil
  end
end
