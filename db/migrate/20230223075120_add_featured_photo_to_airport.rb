class AddFeaturedPhotoToAirport < ActiveRecord::Migration[7.0]
  def change
    add_reference :airports, :featured_photo, foreign_key: {to_table: :active_storage_attachments, on_delete: :nullify}, type: :uuid
  end
end
