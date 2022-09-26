class CreatePostgresCacheStore < ActiveRecord::Migration[7.0]
  def change
    create_table :postgres_cache_store, id: :uuid do |table| # rubocop:disable Rails/CreateTableWithTimestamps
      table.string :key, null: false
      table.text :value
      table.jsonb :entry

      table.index :key, unique: true
    end
  end
end
