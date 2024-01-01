class WeatherReportUpdaterJob < ApplicationJob
  def perform
    AviationWeatherUpdater.new.import!
  end
end
