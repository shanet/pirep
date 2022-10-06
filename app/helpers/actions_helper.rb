module ActionsHelper
  def action_link(action)
    case action.type.to_sym
      when :airport_added
        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{link_to action.actionable.code, airport_path(action.actionable)}: Airport added".html_safe,
        }

      when :airport_edited
        fields_updated = action.version.object_changes.keys.map {|key| key.capitalize.gsub('_', ' ')}

        return {
          icon: 'fa-solid fa-pen-to-square',
          label: "#{link_to action.actionable.code, airport_path(action.actionable)}: Airport edited | #{fields_updated.join(', ')}".html_safe,
        }

      when :airport_photo_uploaded
        return {
          icon: 'fa-solid fa-camera',
          label: "#{link_to action.actionable.code, airport_path(action.actionable)}: Airport photo uploaded".html_safe,
        }

      when :tag_added
        tag = action.actionable.label

        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{link_to action.actionable.airport.code, airport_path(action.actionable.airport)}: Tag added | #{tag}".html_safe,
        }

      when :tag_removed
        tag = Tag::TAGS[action.version.object_changes['name'].first.to_sym][:label]

        return {
          icon: 'fa-solid fa-square-minus',
          label: "#{link_to Airport.find(action.version.airport_id).code, airport_path(action.version.airport_id)}: Tag removed | #{tag}".html_safe,
        }

      when :comment_added
        return {
          icon: 'fa-solid fa-comment',
          label: "#{link_to action.actionable.airport.code, airport_path(action.actionable.airport)}: Comment posted".html_safe,
        }

      when :comment_helpful
        return {
          icon: 'fa-solid fa-thumbs-up',
          label: "#{link_to action.actionable.airport.code, airport_path(action.actionable.airport)}: Comment found helpful".html_safe,
        }

      when :comment_flagged
        return {
          icon: 'fa-solid fa-flag',
          label: "#{link_to action.actionable.airport.code, airport_path(action.actionable.airport)}: Comment flagged as outdated".html_safe,
        }

      when :comment_unflagged
        return {
          icon: 'fa-solid fa-rotate-left',
          label: "#{link_to action.actionable.airport.code, airport_path(action.actionable.airport)}: Comment unflagged as outdated".html_safe,
        }
    end
  end
end
