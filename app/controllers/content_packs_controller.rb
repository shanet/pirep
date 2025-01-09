class ContentPacksController < ApplicationController
  def index
    authorize :content_packs, :index?
  end

  def show
    authorize :content_packs, :show?

    content_pack = params[:id]
    return not_found unless ContentPacksCreator.content_pack?(content_pack)

    path = ContentPacksCreator.path_for_content_pack(content_pack)
    send_file(path, type: 'application/zip', filename: File.basename(path))
  end
end
