class AddGooglePlaceIdToAirports < ActiveRecord::Migration[8.1]
  def change
    add_column :airports, :google_place_id, :string
  end
end
