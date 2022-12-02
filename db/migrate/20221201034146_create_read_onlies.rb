class CreateReadOnlies < ActiveRecord::Migration[7.0]
  def change
    create_table :read_onlies, id: :uuid do |table|
      table.boolean :enabled, null: false, default: false
      table.timestamps
    end
  end
end
