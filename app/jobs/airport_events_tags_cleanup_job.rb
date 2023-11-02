class AirportEventsTagsCleanupJob < ApplicationJob
  def perform
    # Remove the events tag from any airport that does not have any more upcoming events
    Airport.joins(:tags).where(tags: {name: :events}).find_each do |airport|
      next if airport.events.upcoming.any?

      airport.tags.where(name: :events).destroy_all
    end
  end
end
