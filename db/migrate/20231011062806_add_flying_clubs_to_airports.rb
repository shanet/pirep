class AddFlyingClubsToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :flying_clubs, :text
  end
end
