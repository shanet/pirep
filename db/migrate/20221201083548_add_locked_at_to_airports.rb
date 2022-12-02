class AddLockedAtToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :locked_at, :timestamp
  end
end
