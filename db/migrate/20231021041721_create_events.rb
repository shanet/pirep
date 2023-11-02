class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events, id: :uuid do |table|
      table.string :name
      table.text :description
      table.string :location
      table.string :host
      table.string :url
      table.timestamp :start_date
      table.timestamp :end_date
      table.string :recurring_cadence
      table.integer :recurring_interval
      table.integer :recurring_day_of_month
      table.integer :recurring_week_of_month
      table.references :airport, null: false, foreign_key: true, type: :uuid
      table.timestamps
    end
  end
end
