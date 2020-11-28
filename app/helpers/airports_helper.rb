module AirportsHelper
  def options_for_tag_select(airport)
    # Remove already added tags on the airport from the options of tags
    possible_tags = Tag.addable_tags.keys - airport.tags.pluck(:name).map(&:to_sym)
    return options_for_select(possible_tags.map {|tag| [Tag::TAGS[tag][:label], tag]})
  end

  def textarea_editor_height(size)
    case size
      when :large
        return '300px'
      when :small
        return '75px'
      else
        return nil
    end
  end

  def landing_rights_info(airport)
    return {
      public_: 'Private, but open to public',
      restrictions: 'Private, but open to public with restrictions',
      permission: 'Private, but landing allowed with prior permission',
      private_: 'Private to everyone :(',
    }[airport.landing_rights]
  end
end
