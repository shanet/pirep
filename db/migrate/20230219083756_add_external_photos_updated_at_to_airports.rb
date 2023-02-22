class AddExternalPhotosUpdatedAtToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :external_photos_updated_at, :timestamp
  end
end
