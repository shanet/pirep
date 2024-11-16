module AirportsHelper
  include ApplicationHelper

  def show_notices?(airport)
    return airport.empty? || airport.closed? || airport.unmapped?
  end

  def textarea_editor_height(size)
    case size
      when :large
        return '300px'
      when :medium
        return '150px'
      when :small
        return '75px'
      else
        return nil
    end
  end

  def display_version?(version, column)
    return Airport::HISTORY_COLUMNS.keys.include?(column.to_sym) ||
        (version.item_type == 'Event' && column == 'name') ||
        (version.item_type == 'Tag' && column == 'name') ||
        (version.item_type == 'Webcam' && column == 'url')
  end

  def version_author(version)
    # Use `find_by` to handle versions without an author
    user = Users::User.find_by(id: version.whodunnit)
    return 'System' unless user

    if current_user&.admin?
      return link_to user.ip_address, manage_user_path(user) if user.unknown?

      return link_to user.email, manage_user_path(user)
    end

    return link_to user.ip_address, users_show_user_path(user) if user.unknown?

    return link_to user.name.presence || t(:anonymous_label), users_show_user_path(user)
  end

  def version_title(version, column)
    case version.item_type
      when Airport.name
        return "<i class=\"fa-solid fa-pen-to-square\"></i> #{Airport::HISTORY_COLUMNS[column.to_sym]}".html_safe

      when Event.name
        case version.event
          when 'create'
            return '<i class="fa-solid fa-calendar-plus"></i> Event Added'.html_safe
          when 'destroy'
            return '<i class="fa-solid fa-calendar-xmark"></i> Event Removed'.html_safe
        end

      when Tag.name
        case version.event
          when 'create'
            return '<i class="fa-solid fa-square-plus"></i> Tag Added'.html_safe
          when 'destroy'
            return '<i class="fa-solid fa-square-minus"></i> Tag Removed'.html_safe
        end

      when Webcam.name
        case version.event
          when 'create'
            return '<i class="fa-solid fa-camera"></i> Webcam Added'.html_safe
          when 'destroy'
            return '<i class="fa-solid fa-camera"></i> Webcam Removed'.html_safe
        end

      else
        raise 'Unknown version item type'
    end
  end

  def diff(previous, current)
    return Diffy::SplitDiff.new(sanitize(diff_to_s(previous)), sanitize(diff_to_s(current)), format: :html)
  end

  def diff_to_s(annotations)
    return annotations unless annotations.is_a? Array

    # Annotations are stored as JSONB arrays so we need to convert them to a string before passing them into the diff generator
    return annotations.map {|annotation| "#{annotation['label']}: (#{annotation['latitude']}, #{annotation['longitude']})"}.join("\n")
  end

  def opengraph_description(airport, lines: 2)
    if airport.description.present?
      return airport.description.split("\n")[0...lines].join("\n")
    end

    help_text = 'Help us collect information on it at Pirep!'

    # Unmapped airports don't have city/state info so the text below won't work for them
    return "#{airport.name.titleize} is an unmapped airport. #{help_text}" if airport.unmapped?

    location = if airport.city.present? && airport.state.present?
                 " located in #{airport.city.titleize}, #{airport.state}"
               elsif airport.state.present?
                 " located in #{airport.state}"
               end

    return "#{airport.name.titleize} is a #{Airport::FACILITY_USES[airport.facility_use.to_sym].downcase} airport#{location}. #{help_text}"
  end

  def opengraph_image(airport)
    return cdn_url_for(airport.featured_photo) if airport.featured_photo

    return cdn_url_for(airport.contributed_photos.first) if airport.contributed_photos.any?

    return cdn_url_for(airport.external_photos.first) if airport.external_photos.any?

    return image_url('logo_small.png')
  end

  def fuel_label(airport)
    if airport.fuel_types&.any?
      fuel_url = link_to('(prices)', "http://www.100ll.com/searchresults.php?searchfor=#{airport.icao_code || airport.code}", target: :_blank, rel: 'noopener')
      return "#{airport.fuel_types.join(', ')} #{fuel_url}".html_safe
    end

    return 'None'
  end

  def ios?(request)
    # This assumes that the browser isn't changing the user agent (like Firefox for iOS does). But that works in most cases,
    # and this functionality isn't critical so it should be sufficient. This may be worth revisiting if Apple ever stops
    # being dicks and lets third party rendering engines run on iOS.
    return !(request.user_agent =~ /iPhone|iPad/).nil?
  end

  def foreflight_url(airport)
    url = 'foreflightmobile://maps/search?q='

    # There's no code to link to for an unmapped airport so use it's coordinates directly
    return "#{url}#{airport.latitude}/#{airport.longitude}" if airport.unmapped?

    return "#{url}APT@#{airport.icao_code || airport.code}"
  end

  def recurring_event_to_s(event)
    return '' unless event.recurring?

    if event.recurring_interval > 1
      string = "Repeats every #{event.recurring_interval.to_s.humanize.downcase} #{Event::RECURRING_CADENCE[event.recurring_cadence].pluralize(2).downcase}"
    else
      string = "Repeats every #{Event::RECURRING_CADENCE[event.recurring_cadence].downcase}"
    end

    if [:monthly, :yearly].include?(event.recurring_cadence)
      if event.recurring_day_of_month
        string += " on the #{event.recurring_day_of_month.ordinalize}"
      elsif event.recurring_week_of_month
        string += " on the #{event.recurring_week_of_month_label} #{event.start_date.in_time_zone(event.airport.timezone).strftime('%A')}"
      end
    end

    if event.recurring_cadence == :yearly
      string += " of #{event.start_date.in_time_zone(event.airport.timezone).strftime('%B')}"
    end

    return string
  end

  def weather_icon(airport)
    icon = {
      rain: 'fa-cloud-showers-heavy',
      snow: 'fa-snowflake',
      fog: 'fa-cloud',
      wind: 'fa-wind',
      freezing: 'fa-person-skating',
      thunderstorm: 'fa-cloud-bolt',
      smoke: 'fa-smog',
      tornado: 'fa-tornado',
      volcano: 'fa-volcano',
    }[WeatherReportParser.new(airport.metar).weather_category]
    return icon if icon

    return 'fa-wind' if airport.metar.wind_speed&.send(:>=, 20) || airport.metar.wind_gusts&.send(:>=, 20) # kt

    return 'fa-cloud' if airport.metar.ifr? || airport.metar.mvfr?

    # When no other category is determined fallback to a generic sun & clouds icon. Show a moon if it's nighttime though.
    time = Time.zone.now.in_time_zone(airport.timezone)

    unless time.dst? ? time.hour.between?(8, 18) : time.hour.between?(7, 19)
      return (airport.metar.ceiling == Metar::SKY_CLEAR ? 'fa-moon' : 'fa-cloud-moon')
    end

    return (airport.metar.ceiling == Metar::SKY_CLEAR ? 'fa-sun' : 'fa-cloud-sun')
  end

  def weather_background_color(flight_category)
    return {
      'VFR' => 'bg-success-subtle',
      'MVFR' => 'bg-info-subtle',
      'IFR' => 'bg-danger-subtle',
      'LIFR' => 'bg-lifr-subtle',
    }[flight_category] || nil
  end

  def cloud_layers_to_s(weather_report)
    return weather_report.cloud_layers.map do |cloud_layer|
      next "#{Metar::CLOUD_COVERAGE[cloud_layer['coverage']]} @ #{number_with_delimiter cloud_layer['altitude']}ft"
    end.join(', ')
  end
end
