module Manage::DashboardHelper
  def version_summary(version)
    case version.item_type
      when Airport.name
        if version.event == 'destroy' # rubocop:disable Style/GuardClause
          return '<i class="fa-solid fa-trash"></i> Airport deleted'.html_safe
        else
          return "<i class=\"fa-solid fa-pen-to-square\"></i> #{version.object_changes.keys.map {|key| key.gsub('_', ' ').capitalize}.join(', ')}".html_safe
        end

      when Event.name
        if version.event == 'create' # rubocop:disable Style/CaseLikeIf
          return "<i class=\"fa-solid fa-calendar-plus\"></i> Event added: #{version.object_changes['name'].last}".html_safe
        elsif version.event == 'update'
          return "<i class=\"fa-solid fa-calendar-days\"></i> Event updated: #{version.object_changes.keys.map {|key| key.gsub('_', ' ').capitalize}.join(', ')}".html_safe
        elsif version.event == 'destroy'
          return "<i class=\"fa-solid fa-calendar-xmark\"></i> Event removed: #{version.object_changes['name'].first}".html_safe
        end

      when Tag.name
        if version.event == 'create'
          return "<i class=\"fa-solid fa-square-plus\"></i> Tag added: #{version.object_changes['name'].last}".html_safe
        elsif version.event == 'destroy'
          return "<i class=\"fa-solid fa-square-minus\"></i> Tag removed: #{version.object_changes['name'].first}".html_safe
        end

      when Webcam.name
        if version.event == 'create'
          return '<i class="fa-solid fa-square-plus"></i> Webcam added'.html_safe
        elsif version.event == 'destroy'
          return '<i class="fa-solid fa-square-minus"></i> Webcam removed'.html_safe
        end
    end

    return ''
  end
end
