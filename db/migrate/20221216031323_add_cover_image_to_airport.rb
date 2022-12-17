class AddCoverImageToAirport < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :cover_image, :string, null: false, default: 'default'
  end
end
