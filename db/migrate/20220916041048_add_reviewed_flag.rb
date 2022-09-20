class AddReviewedFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :reviewed_at, :timestamp
    add_column :comments, :reviewed_at, :timestamp
    add_column :users, :reviewed_at, :timestamp
    add_column :versions, :reviewed_at, :timestamp
  end
end
