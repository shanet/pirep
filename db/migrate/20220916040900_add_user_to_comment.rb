class AddUserToComment < ActiveRecord::Migration[7.0]
  def change
    add_reference :comments, :user, null: false, foreign_key: true, type: :uuid # rubocop:disable Rails/NotNullColumn
  end
end
