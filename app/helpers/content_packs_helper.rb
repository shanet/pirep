module ContentPacksHelper
  include ApplicationHelper

  def airport_icon(airport)
    return ContentPacksCreator.airport_icon(airport)
  end

  def content_pack_icons
    return ContentPacksCreator.icons
  end
end
