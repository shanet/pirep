class AddTimezoneToAirports < ActiveRecord::Migration[7.1]
  def change
    change_table :airports, bulk: true do |table|
      table.string :timezone
      table.timestamp :timezone_checked_at
    end
  end
end
