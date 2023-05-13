class AirportsController < ApplicationController
  layout 'blank'

  before_action :set_airport, only: [:update, :history, :uncached_photo_gallery]
  before_action :set_airport_by_code, only: [:show, :annotations]
  after_action :record_pageview, only: :show

  def index
    authorize :airport, :index?

    # This is stored as a cached asset in production since dumping all airports to JSON takes a while
    cache = AirportGeojsonDumper.cached

    if cache
      redirect_to "#{Rails.configuration.action_controller.asset_host || ''}#{cache}", allow_other_host: true
    else
      render json: Airport.geojson.to_json
    end
  end

  def new
    @airport = Airport.new
    authorize @airport
  end

  def create
    @airport = Airport.new_unmapped(new_airport_params)
    authorize @airport

    if @airport.save
      # It's unlikely, but try to get a bounding box for the new airport just in case one exists
      FetchAirportBoundingBoxJob.perform_later(@airport)

      Action.create!(type: :airport_added, actionable: @airport, user: active_user)

      # Schedule an airport cache refresh so the new airport shows up on the map before the next refresh cycle
      AirportGeojsonDumperJob.perform_later

      flash[:notice] = 'New airport added to map, please fill out any known additional information about it.'
      render :create
    else
      @form_element_id = 'new-airport'
      render :error_response
    end
  end

  def show
    return not_found(request.format.symbol) unless @airport
  end

  def update
    # Ensure that the update won't overwrite a change that another user already made
    return head(:conflict) if airport_write_conflict?(@airport, params[:airport][:rendered_at])

    if @airport.update(airport_params) && @airport.attach_contributed_photos((params[:airport][:photos] || []).compact_blank)
      touch_author
      create_actions

      # Schedule an airport cache refresh if the tags changed so the changes are reflected on the map before the next refresh cycle
      if airport_params['tags_attributes']
        AirportGeojsonDumperJob.perform_later
      end

      if request.xhr?
        # Add one second to avoid a time conflict with the version that was just created
        render json: {timestamp: 1.second.from_now.iso8601}
      else
        redirect_to airport_path(@airport.code)
      end
    else
      (request.xhr? ? render(json: @airport.errors.full_messages) : render(:show))
    end
  end

  def search
    authorize :airport, :search?

    coordinates = (params['latitude'] && params['longitude'] ? {latitude: params['latitude'].to_f, longitude: params['longitude'].to_f} : nil)

    # Don't use wildcard searches if searching by an airport code (3 or 4 letters) as this will yield odd results for FAA codes that start with an ICAO prefix
    wildcard = !params['query'].length.in?([3, 4])

    results = Search.query(params['query'], Airport, coordinates, wildcard: wildcard).limit(10).uniq
    render json: results.map {|airport| {code: airport.code, label: airport.name&.titleize, bounding_box: airport.bounding_box, zoom_level: airport.zoom_level}}
  end

  def history
    @versions = @airport.all_versions.page(params[:page])
    @total_records = @airport.all_versions.count
  end

  def preview
    @airport = PaperTrail::Version.find(params[:version_id]).reify

    unless @airport
      skip_authorization
      return not_found
    end

    authorize @airport
    render :show
  end

  def revert
    @airport = PaperTrail::Version.find(params[:version_id]).reify
    authorize @airport

    # This is an admin only action and if it fails it's likely something complex that we shouldn't try to gracefully recover from
    @airport.save!
    redirect_to airport_path(@airport.code), notice: 'Airport reverted to previous version'
  end

  def annotations
    return not_found unless @airport

    render json: @airport.annotations
  end

  def uncached_photo_gallery
    # If the request is from a spider don't do anything. The Google Place Photos API is kind of expensive.
    return head :no_content if spider?

    return not_found unless @airport

    @uncached_external_photos = @airport.uncached_external_photos
    return head :no_content unless @uncached_external_photos

    @border = ActiveModel::Type::Boolean.new.cast(params[:border])
    render :uncached_photo_gallery, layout: false
  end

private

  def set_airport
    @airport = Airport.find(params[:id])
    authorize @airport
  end

  def set_airport_by_code
    @airport = Airport.find_by(code: params[:id].upcase) || Airport.find_by(icao_code: params[:id].upcase) || Airport.find(params[:id])
    authorize @airport
  end

  def airport_params
    # Filter out any tags that are not selected since the UI shows all tags as options to add
    params['airport']&.[]('tags_attributes')&.select! {|_index, tag| tag['selected'] == 'true'}

    return params.require(:airport).permit(
      :description,
      :transient_parking,
      :fuel_location,
      :landing_fees,
      :crew_car,
      :wifi,
      :landing_rights,
      :landing_requirements,
      :annotations,
      :cover_image,
      :featured_photo_id,
      tags_attributes: [:name]
    )
  end

  def new_airport_params
    return params.require(:airport).permit(
      :name,
      :latitude,
      :longitude,
      :elevation,
      :landing_rights,
      :landing_requirements,
      :state,
      tags_attributes: [:name]
    )
  end

  def touch_author
    # Keep track of when a user last made an edit
    active_user&.touch(:last_edit_at) # rubocop:disable Rails/SkipsModelValidations
  end

  def create_actions
    # Create an action for each added tag
    if airport_params[:tags_attributes] # rubocop:disable Style/SafeNavigation
      airport_params[:tags_attributes].each do |_key, tag|
        Action.create!(type: :tag_added, actionable: @airport.tags.find_by(name: tag[:name]), user: active_user)
      end
    end

    # Also (or) create an action for any edits to the airport
    if airport_params.except(:tags_attributes).to_h.any?
      Action.transaction do
        # Lock the version to prevent the versions collation job from deleting it while we're using it here
        version = @airport.versions.reload.lock!.last
        Action.create!(type: :airport_edited, actionable: @airport, user: active_user, version: version)
      end
    end

    if params[:airport][:photos] # rubocop:disable Style/GuardClause
      Action.create!(type: :airport_photo_uploaded, actionable: @airport, user: active_user)
    end
  end

  def user_for_paper_trail
    return active_user.id
  end

  def airport_write_conflict?(airport, timestamp)
    edited_fields = airport_params.select {|column, _value| Airport::TEXTAREA_EDITABLE_COLUMNS[column.to_sym]}

    # For each field that was edited, check if there was a conflicting update to it made between when the page was rendered and the update request.
    # The existance of the column name in any version's changed columns after the given timestamp is sufficient to establish a conflict.
    edited_fields.each do |column, _value|
      return true if airport.versions.where('created_at > ?', timestamp).where('object_changes ? :column', column: column).any?
    end

    return false
  end

  def record_pageview
    # Skip recording pageviews for spiders
    return if Pageview.spider?(request.user_agent)

    @airport.pageviews << Pageview.new(user: active_user, ip_address: request.remote_ip, user_agent: request.user_agent)
  end
end
