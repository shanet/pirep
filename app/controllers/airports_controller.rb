class AirportsController < ApplicationController
  include SearchQueryable

  layout 'blank'

  before_action :set_airport, only: [:update, :history]

  def index
    authorize :airport, :index?
    render json: Airport.geojson.to_json
  end

  def show
    @airport = Airport.find_by(code: params[:id].upcase) || Airport.find_by(code: params[:id].upcase.gsub(/^K/, '')) || Airport.find(params[:id])
    authorize @airport

    return not_found(request.format.symbol) unless @airport
  end

  def update
    if @airport.update(airport_params) && @airport.photos.attach(params[:airport][:photos] || [])
      touch_author
      create_actions

      if request.xhr?
        head :ok
      else
        redirect_to airport_path(@airport.code)
      end
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

  def search
    authorize :airport, :search?

    coordinates = (params['latitude'] && params['longitude'] ? {latitude: params['latitude'].to_f, longitude: params['longitude'].to_f} : nil)

    results = Search.query(preprocess_query, Airport, coordinates, wildcard: true).limit(10).uniq
    render json: results.map {|airport| {code: airport.code, label: airport.name}}
  end

  def history
    @versions = @airport.all_versions.page(params[:page])
  end

  def preview
    @airport = PaperTrail::Version.find(params[:version_id]).reify
    authorize @airport
    render :show
  end

  def revert
    @airport = PaperTrail::Version.find(params[:version_id]).reify
    authorize @airport

    if @airport.save
      redirect_to airport_path(@airport.code), notice: 'Airport reverted to previous version'
    else # rubocop:disable Style/EmptyElse
      # TODO: error handle
    end
  end

private

  def set_airport
    @airport = Airport.find(params[:id])
    authorize @airport
  end

  def airport_params
    # Filter out any tags that are not selected since the UI shows all tags as options to add
    params['airport']&.[]('tags_attributes')&.select! {|_index, tag| tag['selected'] == 'true'}

    params.require(:airport).permit(
      :description,
      :transient_parking,
      :fuel_location,
      :landing_fees,
      :crew_car,
      :wifi,
      :landing_rights,
      :landing_requirements,
      :annotations,
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
      Action.create!(type: :airport_edited, actionable: @airport, user: active_user, version: @airport.versions.last)
    end

    if params[:airport][:photos] # rubocop:disable Style/GuardClause
      Action.create!(type: :airport_photo_uploaded, actionable: @airport, user: active_user)
    end
  end

  def user_for_paper_trail
    return active_user.id
  end
end
