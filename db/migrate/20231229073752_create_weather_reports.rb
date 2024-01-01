class CreateWeatherReports < ActiveRecord::Migration[7.1]
  def change
    create_table :weather_reports, id: :uuid do |table|
      table.float :dewpoint
      table.float :temperature
      table.integer :visibility
      table.integer :wind_direction
      table.integer :wind_gusts
      table.integer :wind_speed
      table.jsonb :cloud_layers
      table.references :airport, null: false, foreign_key: true, type: :uuid
      table.string :flight_category
      table.string :raw
      table.string :type
      table.string :weather
      table.timestamp :ends_at
      table.timestamp :observed_at
      table.timestamp :starts_at

      table.timestamps
    end
  end
end
