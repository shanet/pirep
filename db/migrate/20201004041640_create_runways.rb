class CreateRunways < ActiveRecord::Migration[6.0]
  def change
    create_table :runways, id: :uuid do |table|
      table.string :number, null: false
      table.integer :length, null: false
      table.string :surface
      table.string :lights
      table.references :airport, null: false, foreign_key: true, type: :uuid

      table.timestamps
    end
  end
end
