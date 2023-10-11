module AirportsHelper
  include ApplicationHelper

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

  def version_author(version)
    # Use `find_by` to handle versions without an author
    user = Users::User.find_by(id: version.whodunnit)
    return 'System' unless user

    if user.unknown?
      return link_to user.ip_address, manage_user_path(user)
    end

    return link_to user.email, manage_user_path(user)
  end

  def version_title(version, column)
    if version.item_type == Tag.name
      case version.event
        when 'create'
          return '<i class="fa-solid fa-square-plus"></i> Tag Added'.html_safe
        when 'destroy'
          return '<i class="fa-solid fa-square-minus"></i> Tag Removed'.html_safe
      end
    end

    return "<i class=\"fa-solid fa-pen-to-square\"></i> #{Airport::HISTORY_COLUMNS[column.to_sym]}".html_safe
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

    return "#{airport.name.titleize} is a #{Airport::FACILITY_USES[airport.facility_use.to_sym].downcase} airport located in #{airport.city.titleize}, #{airport.state}. #{help_text}"
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
end
