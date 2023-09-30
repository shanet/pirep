class AddUniqueIndexForWebcamUrls < ActiveRecord::Migration[7.0]
  def change
    add_index :webcams, [:url, :airport_id], unique: true
  end
end
