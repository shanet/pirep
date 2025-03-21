module ContentPacksHelper
  include ApplicationHelper

  def airport_icon(airport)
    return ContentPacksCreator.airport_icon(airport)
  end

  def content_pack_icons
    return ContentPacksCreator.icons
  end

  def content_pack_versioned_url(content_pack_id)
    # Add the timestamp of the current content pack as a query param so if the CDN is used we bust its cache when a new content pack is issued
    url = content_pack_path(content_pack_id, version: File.basename(ContentPacksCreator.path_for_content_pack(content_pack_id) || '').split('_').last)

    # Serve the content pack from the CDN if its configured
    url = "#{Rails.configuration.action_controller.asset_host}/#{url}" if Rails.configuration.action_controller.asset_host.present?

    return url
  end
end
