class AddDataSourceToEvents < ActiveRecord::Migration[7.1]
  def change
    change_table :events, bulk: true do |table|
      table.string :data_source
      table.string :digest
      table.index [:digest, :airport_id], unique: true
    end
  end
end
