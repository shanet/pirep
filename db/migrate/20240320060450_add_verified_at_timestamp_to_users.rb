class AddVerifiedAtTimestampToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :verified_at, :timestamp
  end
end
