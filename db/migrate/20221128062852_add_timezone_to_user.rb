class AddTimezoneToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :timezone, :string
  end
end
