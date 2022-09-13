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
    user = Users::User.find_by(id: version.whodunnit)
    return 'Unknown' unless user

    case user.type
      when Users::Unknown.to_s
        return link_to user.ip_address, manage_user_path(user)
      else
        return link_to user.email, manage_user_path(user)
    end
  end

  def version_title(version, column)
    if version.item_type == 'Tag'
      case version.event
        when 'create'
          return 'Tag Added'
        when 'destroy'
          return 'Tag Removed'
      end
    end

    return Airport::HISTORY_COLUMNS[column.to_sym]
  end

  def diff(previous, current)
    return Diffy::SplitDiff.new(sanitize(previous), sanitize(current), format: :html)
  end
end
