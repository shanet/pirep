class MapController < ApplicationController
  layout 'map'

  def index
    authorize :map
  end
end
