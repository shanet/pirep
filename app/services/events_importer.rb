require 'aopa/aopa_api'
require 'eaa/eaa_api'

class EventsImporter
  AIRPORT_SEARCH_RADIUS = 10 # miles

  def import!
    import_aopa_events!
    import_eaa_events!

    # Schedule a geojson dump so airports with new events show up on the map
    AirportGeojsonDumperJob.perform_later
  end

private

  def import_aopa_events!
    Rails.logger.info('Importing AOPA events')
    events = AopaApi.client.fetch_events

    Rails.logger.info("Found #{events.count} AOPA events")
    create_events!(events, :aopa)
  end

  def import_eaa_events!
    Rails.logger.info('Importing EAA events')
    events = EaaApi.client.fetch_events

    Rails.logger.info("Found #{events.count} EAA events")
    create_events!(events, :eaa)
  end

  def create_events!(events, data_source)
    events.each do |event|
      # The times should not be TimeWithZone objects as that will mess up the timezone injection below
      raise('Event has start date with timezone') if event[:start_date].is_a?(ActiveSupport::TimeWithZone)

      airport = airport_for_event(event)

      # Skip events that we couldn't match a matching airport for
      unless airport
        Rails.logger.info("Unable to find host airport for event #{event[:name]} at (#{event[:latitude]}, #{event[:longitude]})")
        next
      end

      # Put the event's start/end dates into the airport's local timezone
      Time.use_zone(airport.timezone || Rails.configuration.time_zone) do
        event[:start_date] = Time.zone.parse(event[:start_date])
        event[:end_date] = Time.zone.parse(event[:end_date])
      end

      next if !valid_event?(event) || duplicate_event?(event, airport)

      normalize_event!(event)

      Event.create!(
        name: event[:name],
        start_date: event[:start_date],
        end_date: event[:end_date],
        url: event[:url],
        airport: airport,
        data_source: data_source,
        digest: event[:digest]
      )
    rescue => error
      Rails.logger.info("Failed to import event: #{error}")
      Sentry.capture_exception(error)
      raise error if Rails.env.test?
    end
  end

  def airport_for_event(event)
    latitude = event[:latitude].to_f
    longitude = event[:longitude].to_f
    order = ApplicationRecord.sanitize_sql_for_order([Arel.sql('coordinates <-> point(?, ?)'), latitude, longitude])

    # Scope the facility types down to only airports since it's possible that there's heliports
    # or seaplane bases within an airport and it's not likely for events to be happening there.
    conditions = {facility_type: :airport, facility_use: 'PU'}
    sanity_check = "coordinates <@> point(?, ?) < #{AIRPORT_SEARCH_RADIUS}"

    # First try to find all public airports with the same city and state as the event if one was given
    if event[:city].present? && event[:state].present?
      airport = Airport.where(**conditions.merge(city: event[:city].upcase, state: event[:state].upcase)).where(sanity_check, latitude, longitude).order(order).first
      return airport if airport
    end

    # Now just try to find public airports
    airport = Airport.where(**conditions).where(sanity_check, latitude, longitude).order(order).first
    return airport if airport

    # If still nothing try private airports before giving up
    conditions.delete(:facility_use)
    return Airport.where(**conditions).where(sanity_check, latitude, longitude).order(order).first
  end

  def valid_event?(event)
    # No use in importing events that are in the past
    if event[:start_date] < Time.zone.now
      Rails.logger.info('Event has start date in the past, ignoring')
      return false
    end

    if event[:end_date] < event[:start_date]
      Rails.logger.info('Event has end date earlier than start date, ignoring')
      return false
    end

    return true
  end

  def duplicate_event?(event, airport)
    # Don't create duplicate events when re-importing (this uses a digest created at import-time so that a user edit event value doesn't import another event)
    if event[:digest].in?(airport.events.pluck(:digest))
      Rails.logger.info("Duplicate event for airport #{airport.id}: #{event[:name]}, #{event[:url]}")
      return true
    end

    return false
  end

  def normalize_event!(event)
    # If the start and end date/time are the same bump the end date by an hour to avoid a validation error
    if event[:start_date] == event[:end_date]
      event[:end_date] += 1.hour
    end

    event[:digest] ||= event_digest(event)
  end

  def event_digest(event)
    # This is primarily a fallback for if an event digest is not provided by the individual data source
    return Digest::SHA256.hexdigest("#{event[:name]}/#{event[:start_date].iso8601}")
  end
end
