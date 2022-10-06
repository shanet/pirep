class CreateActions < ActiveRecord::Migration[7.0]
  def change
    create_table :actions, id: :uuid do |table|
      table.string :type
      table.references :user, null: false, foreign_key: true, type: :uuid
      table.references :actionable, polymorphic: true, null: false, type: :uuid
      table.references :version, foreign_key: true, type: :uuid

      table.timestamps
    end
  end
end
