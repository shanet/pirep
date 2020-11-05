class CreateTags < ActiveRecord::Migration[6.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name
      t.belongs_to :airport, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
