class AddFaaDataCycles < ActiveRecord::Migration[7.0]
  def change
    create_table :faa_data_cycles, id: :uuid do |table|
      table.string :airports
      table.string :charts
      table.string :diagrams
      table.timestamps
    end
  end
end
