# frozen_string_literal: true

class AddIndexUsersTypeCreatedAtUnreviewed < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :users, [:type, :created_at],
              order: {created_at: :desc},
              name: :index_users_on_type_and_created_at_unreviewed,
              where: 'reviewed_at IS NULL',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
