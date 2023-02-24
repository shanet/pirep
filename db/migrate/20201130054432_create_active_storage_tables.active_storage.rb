# This migration comes from active_storage (originally 20170806125915)
class CreateActiveStorageTables < ActiveRecord::Migration[5.2]
  def change
    create_table :active_storage_blobs, id: :uuid do |table|
      table.string :key, null: false
      table.string :filename, null: false
      table.string :content_type
      table.text :metadata
      table.bigint :byte_size, null: false
      table.string :checksum, null: false
      table.datetime :created_at, null: false
      table.index [:key], unique: true
    end

    create_table :active_storage_attachments, id: :uuid do |table|
      table.string :name, null: false
      table.references :record, null: false, polymorphic: true, index: false, type: :uuid
      table.references :blob, null: false, type: :uuid
      table.datetime :created_at, null: false
      table.index [:record_type, :record_id, :name, :blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
      table.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
