class AddIpAddressToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :ip_address, :string
    add_index :users, :ip_address, unique: true
  end
end
