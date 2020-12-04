class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments, id: :uuid do |table|
      table.references :airport, null: false, foreign_key: true, type: :uuid
      table.text :body
      table.integer :helpful_count, default: 0
      table.datetime :outdated_at

      table.timestamps
    end
  end
end
