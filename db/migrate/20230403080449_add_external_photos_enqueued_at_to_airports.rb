class AddExternalPhotosEnqueuedAtToAirports < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :external_photos_enqueued_at, :timestamp
  end
end
