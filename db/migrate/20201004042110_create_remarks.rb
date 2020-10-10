class CreateRemarks < ActiveRecord::Migration[6.0]
  def change
    create_table :remarks, id: :uuid do |table|
      table.string :element, null: false
      table.text :text, null: false
      table.references :airport, null: false, foreign_key: true, type: :uuid

      table.timestamps
    end
  end
end
