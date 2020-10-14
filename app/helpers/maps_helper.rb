module MapsHelper
  def tag_icon(tag)
    tag = Tag::TAGS[tag.to_sym]
    return "<i class=\"fas fa-#{tag[:icon]}\"></i>".html_safe
  end
end
