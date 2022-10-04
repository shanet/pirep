class AddSearch < ActiveRecord::Migration[7.0]
  def change
    create_table :searches, id: :uuid do |table| # rubocop:disable Rails/CreateTableWithTimestamps
      table.references :searchable, null: false, polymorphic: true, type: :uuid
      table.tsvector :term_vector, null: false
      table.string :term, null: false
      table.point :coordinates

      # Create a gin index for search performance and an index for upsert statements when reindexing individual records
      table.index :term_vector, using: :gin
      table.index [:searchable_id, :searchable_type, :term], unique: true
    end
  end
end
