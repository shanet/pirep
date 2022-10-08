class AddFaaDataCycleToAirport < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :faa_data_cycle, :timestamp
  end
end
