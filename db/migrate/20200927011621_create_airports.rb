class CreateAirports < ActiveRecord::Migration[6.0]
  def change
    create_table :airports, id: :uuid do |table|
      table.string :name, null: false
      table.string :code, null: false, index: {unique: true}
      table.float :latitude, null: false
      table.float :longitude, null: false
      table.string :site_number, null: false, index: {unique: true}
      table.string :facility_type
      table.string :facility_use
      table.string :ownership_type
      table.string :owner_name
      table.string :owner_phone
      table.text :description
      table.text :transient_parking
      table.text :fuel_location
      table.text :crew_car
      table.text :landing_fees
      table.text :wifi
      table.text :passport_location
      table.integer :elevation, null: false
      table.string :fuel_type
      table.string :gate_code

      table.timestamps
    end
  end
end
