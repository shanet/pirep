class AddNewFieldsToAirport < ActiveRecord::Migration[7.0]
  def change
    change_table :airports, bulk: true do |table|
      table.remove :site_number
      table.remove :owner_name
      table.remove :owner_phone
      table.remove :fuel_type
      table.remove :passport_location
      table.remove :gate_code

      table.string :city
      table.string :state
      table.float :city_distance
      table.string :sectional
      table.timestamp :activation_date
      table.string :fuel_types, array: true
    end
  end
end
