class CreateTaggings < ActiveRecord::Migration[6.0]
  def change
    create_table :taggings, id: :uuid do |t|
      t.belongs_to :airport, null: false, foreign_key: true, type: :uuid
      t.belongs_to :tag, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
