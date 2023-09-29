class CreateWebcams < ActiveRecord::Migration[7.0]
  def change
    create_table :webcams, id: :uuid do |table|
      table.references :airport, null: false, foreign_key: true, type: :uuid
      table.string :url

      table.timestamps
    end
  end
end
