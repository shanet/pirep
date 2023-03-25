class AddIcaoCodeToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :icao_code, :string, unique: true
  end
end
