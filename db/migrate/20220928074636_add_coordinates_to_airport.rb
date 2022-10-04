class AddCoordinatesToAirport < ActiveRecord::Migration[7.0]
  def change
    add_column :airports, :coordinates, :point

    # These are needed to use the point-based earthdistance operator
    # See https://www.postgresql.org/docs/current/earthdistance.html
    enable_extension 'cube'
    enable_extension 'earthdistance'
  end
end
