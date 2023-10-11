class VersionsController < ApplicationController
  def revert
    version = PaperTrail::Version.find(params[:id])

    # Don't revert an already reverted version
    if version.reverted_at.present?
      skip_authorization
      return bad_request
    end

    authorize(version.item || version.reify)

    # This is an admin only action and if it fails it's likely something complex that we shouldn't try to gracefully recover from
    case version.event
      when 'create'
        record = version.item
        record.destroy!
      when 'update', 'destroy'
        record = version.reify
        record.save!
    end

    # Mark the version as reverted so it doesn't get reverted again and can be filtered out on the UI
    version.update_column(:reverted_at, Time.zone.now) # rubocop:disable Rails/SkipsModelValidations

    redirect_to redirect_path(record), notice: "#{record.class.name.humanize} reverted"
  end

private

  def redirect_path(record)
    return airport_path(record.airport) if record.respond_to?(:airport)

    return airport_path(record)
  end
end
