class AddLandingRightsToAirport < ActiveRecord::Migration[6.0]
  def change
    change_table :airports, bulk: true do |table|
      table.string :landing_rights
      table.string :landing_requirements
    end
  end
end
