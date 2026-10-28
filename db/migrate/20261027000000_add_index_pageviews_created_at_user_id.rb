# frozen_string_literal: true

class AddIndexPageviewsCreatedAtUserId < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :pageviews, [:created_at, :user_id],
              name: :index_pageviews_on_created_at_and_user_id,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
