class CreatePageviews < ActiveRecord::Migration[7.0]
  def change
    create_table :pageviews, id: :uuid do |table|
      table.references :record, polymorphic: true, null: false, type: :uuid
      table.references :user, null: false, foreign_key: true, type: :uuid
      table.string :user_agent
      table.string :browser
      table.string :browser_version
      table.string :operating_system
      table.float :latitude
      table.float :longitude
      table.string :ip_address

      table.timestamps
    end
  end
end
