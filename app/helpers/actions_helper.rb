module ActionsHelper
  DELETED = '[deleted]'

  def action_link(action)
    case action.type.to_sym
      when :airport_added
        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport added".html_safe,
        }

      when :airport_edited
        # Skip any version that didn't actually make any changes
        return nil unless action.version.object_changes

        fields_updated = action.version.object_changes.keys.map {|key| key.capitalize.gsub('_', ' ')}

        return {
          icon: 'fa-solid fa-pen-to-square',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport edited | #{fields_updated.join(', ')}".html_safe,
        }

      when :airport_photo_uploaded
        return {
          icon: 'fa-solid fa-camera',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport photo uploaded".html_safe,
        }

      when :tag_added
        tag_label = Tag::TAGS[action.historical_value(:name)&.to_sym]&.[](:label)
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Tag added | #{tag_label.presence || DELETED}".html_safe,
        }

      when :tag_removed
        tag_label = Tag::TAGS[action.historical_value(:name)&.to_sym]&.[](:label)
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-square-minus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Tag removed | #{tag_label.presence || DELETED}".html_safe,
        }

      when :comment_added
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-comment',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment posted".html_safe,
        }

      when :comment_helpful
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-thumbs-up',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment found helpful".html_safe,
        }

      when :comment_flagged
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-flag',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment flagged as outdated".html_safe,
        }

      when :comment_unflagged
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-rotate-left',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment unflagged as outdated".html_safe,
        }

      when :webcam_added
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-camera',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Airport webcam added".html_safe,
        }
    end
  end
end
