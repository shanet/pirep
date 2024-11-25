module ActionsHelper
  DELETED = '[deleted]'

  def action_link(action)
    case action.type.to_sym
      when :airport_added
        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport added".html_safe,
          points: UserPointsCalculator.points_for_action(:airport_added),
        }

      when :airport_edited
        # Skip any version that didn't actually make any changes
        return nil unless action.version.object_changes

        fields_updated = action.version.object_changes.keys.map {|key| key.capitalize.gsub('_', ' ')}

        return {
          icon: 'fa-solid fa-pen-to-square',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport edited | #{fields_updated.join(', ')}".html_safe,
          points: UserPointsCalculator.points_for_action(:airport_edited),
        }

      when :airport_photo_uploaded
        return {
          icon: 'fa-solid fa-camera',
          label: "#{action.actionable ? link_to(action.actionable.code, airport_path(action.actionable)) : DELETED}: Airport photo uploaded".html_safe,
          points: UserPointsCalculator.points_for_action(:airport_photo_uploaded),
        }

      # -----------------------------------------------------------------------

      when :comment_added
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-comment',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment posted".html_safe,
          points: UserPointsCalculator.points_for_action(:comment_added),
        }

      when :comment_helpful
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-thumbs-up',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment found helpful".html_safe,
          points: UserPointsCalculator.points_for_action(:comment_helpful),
        }

      when :comment_flagged
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-flag',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment flagged as outdated".html_safe,
          points: UserPointsCalculator.points_for_action(:comment_flagged),
        }

      when :comment_unflagged
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-rotate-left',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Comment unflagged as outdated".html_safe,
          points: UserPointsCalculator.points_for_action(:comment_unflagged),
        }

      # -----------------------------------------------------------------------

      when :event_added
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-calendar-plus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Event added".html_safe,
          points: UserPointsCalculator.points_for_action(:event_added),
        }

      when :event_edited
        airport = action.actionable&.airport

        return {
          icon: 'fa-solid fa-calendar-days',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Event updated".html_safe,
          points: UserPointsCalculator.points_for_action(:event_edited),
        }

      when :event_removed
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-calendar-xmark',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Event removed".html_safe,
          points: UserPointsCalculator.points_for_action(:event_removed),
        }

      # -----------------------------------------------------------------------

      when :tag_added
        tag_label = Tag::TAGS[action.historical_value(:name)&.to_sym]&.[](:label)
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-square-plus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Tag added | #{tag_label.presence || DELETED}".html_safe,
          points: UserPointsCalculator.points_for_action(:tag_added),
        }

      when :tag_removed
        tag_label = Tag::TAGS[action.historical_value(:name)&.to_sym]&.[](:label)
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-square-minus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Tag removed | #{tag_label.presence || DELETED}".html_safe,
          points: UserPointsCalculator.points_for_action(:tag_removed),
        }

      # -----------------------------------------------------------------------

      when :webcam_added
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-camera',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Webcam added".html_safe,
          points: UserPointsCalculator.points_for_action(:webcam_added),
        }

      when :webcam_removed
        airport = Airport.find_by(id: action.historical_value(:airport_id))

        return {
          icon: 'fa-solid fa-square-minus',
          label: "#{airport ? link_to(airport.code, airport_path(airport)) : DELETED}: Webcam removed".html_safe,
          points: UserPointsCalculator.points_for_action(:webcam_removed),
        }
    end

    return nil
  end
end
