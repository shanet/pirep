class EventsImporterJob < ApplicationJob
  def perform
    EventsImporter.new.import!
  end
end
