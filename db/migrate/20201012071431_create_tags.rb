class CreateTags < ActiveRecord::Migration[6.0]
  def change
    create_table :tags, id: :uuid do |table|
      table.string :name
      table.belongs_to :airport, null: false, foreign_key: true, type: :uuid

      table.timestamps
    end
  end
end
