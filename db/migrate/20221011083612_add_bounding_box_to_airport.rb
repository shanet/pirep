class AddBoundingBoxToAirport < ActiveRecord::Migration[7.0]
  def change
    change_table :airports, bulk: true do |table|
      table.float :bbox_ne_latitude
      table.float :bbox_ne_longitude
      table.float :bbox_sw_latitude
      table.float :bbox_sw_longitude
    end
  end
end
