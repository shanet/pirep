class AirportGeojsonDumperJob < ApplicationJob
  def perform
    AirportGeojsonDumper.new.write_to_file
  end
end
