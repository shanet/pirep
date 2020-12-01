class AddAirportDiagramToAirport < ActiveRecord::Migration[6.0]
  def change
    add_column :airports, :diagram, :string
  end
end
