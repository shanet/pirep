module AirportsHelper
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
    if version.item_type == 'Tag'
      case version.event
        when 'create'
          return '<i class="fa-solid fa-square-plus"></i> Tag Added'.html_safe
        when 'destroy'
          return '<i class="fa-solid fa-square-minus"></i> Tag Removed'.html_safe
      end
    end

    return '<i class="fa-solid fa-pen-to-square"></i> '.html_safe + Airport::HISTORY_COLUMNS[column.to_sym]
  end

  def diff(previous, current)
    return Diffy::SplitDiff.new(sanitize(previous), sanitize(current), format: :html)
  end

  def airport_satellite_image(airport)
    url = 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v11/static/'
    image_size = [1000, 1280] # px, width,height

    # Use the bounding box if we have one, otherwise fallback to a centered image on the airport's location
    if airport.has_bounding_box?
      bounding_box = [airport.bbox_sw_longitude, airport.bbox_sw_latitude, airport.bbox_ne_longitude, airport.bbox_ne_latitude]
      url += "[#{bounding_box.join(',')}]/#{image_size.join('x')}?padding=75&"
    else
      # For airport types that don't use a bounding box (heliports for instance) we should zoom in further as they occupy much less space than fixed wing airports
      zoom_level = (airport.uses_bounding_box? ? 16 : 17)
      url += "#{airport.longitude},#{airport.latitude},#{zoom_level}/#{image_size.join('x')}?"
    end

    return url + "access_token=#{Rails.application.credentials.mapbox_api_key}"
  end
end
