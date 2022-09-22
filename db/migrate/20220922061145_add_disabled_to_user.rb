class AddDisabledToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :disabled_at, :timestamp
  end
end
