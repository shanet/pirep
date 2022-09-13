class AddLastEditedAtTimestampToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_edit_at, :timestamp
  end
end
