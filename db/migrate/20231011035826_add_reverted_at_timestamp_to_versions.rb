class AddRevertedAtTimestampToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :reverted_at, :datetime
  end
end
