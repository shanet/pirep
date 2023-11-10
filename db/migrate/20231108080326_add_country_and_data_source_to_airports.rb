class AddCountryAndDataSourceToAirports < ActiveRecord::Migration[7.1]
  def change
    change_table :airports, bulk: true do |table|
      table.string :country
      table.string :data_source
    end
  end
end
