module AirportsHelper
  def options_for_tag_select(airport)
    # Remove already added tags on the airport from the options of tags
    possible_tags = Tag.addable_tags.keys - airport.tags.pluck(:name).map(&:to_sym)
    return options_for_select(possible_tags.map {|tag| [Tag::TAGS[tag][:label], tag]})
  end
end
