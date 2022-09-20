class AddLastEditedAtTimestampToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |table|
      table.timestamp :last_edit_at
      table.timestamp :last_seen_at
    end
  end
end
