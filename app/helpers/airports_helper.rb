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
    return Diffy::SplitDiff.new(sanitize(diff_to_s(previous)), sanitize(diff_to_s(current)), format: :html)
  end

  def diff_to_s(annotations)
    return annotations unless annotations.is_a? Array

    # Annotations are stored as JSONB arrays so we need to convert them to a string before passing them into the diff generator
    return annotations.map {|annotation| "#{annotation['label']}: (#{annotation['latitude']}, #{annotation['longitude']})"}.join("\n")
  end

  def opengraph_description(airport)
    if airport.description.present?
      return airport.description.split("\n")[0...2].join("\n")
    end

    return "#{airport.name.titleize} is a #{Airport::FACILITY_USES[airport.facility_use.to_sym].downcase} airport located in #{airport.city.titleize}, #{airport.state}. " \
      "Help us collect information on this airport at Pirep!"
  end
end
