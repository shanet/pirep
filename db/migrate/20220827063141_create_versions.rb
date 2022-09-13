class CreateVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :versions, id: :uuid do |table|
      table.string   :item_type, null: false
      table.string   :item_id,   null: false
      table.string   :event,     null: false
      table.string   :airport_id
      table.string   :whodunnit
      table.jsonb    :object
      table.jsonb    :object_changes
      table.datetime :created_at
    end

    add_index :versions, [:item_type, :item_id]
  end
end
