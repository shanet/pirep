class AddLandingRightsToAirport < ActiveRecord::Migration[6.0]
  def change
  	add_column :airports, :landing_rights, :string
  	add_column :airports, :landing_requirements, :string
  end
end
