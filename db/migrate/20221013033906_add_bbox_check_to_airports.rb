class AddBboxCheckToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :bbox_checked, :boolean, null: false, default: false
  end
end
