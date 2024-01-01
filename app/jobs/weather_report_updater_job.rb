class WeatherReportUpdaterJob < ApplicationJob
  def perform
    WeatherReportUpdater.new.update!
  end
end
