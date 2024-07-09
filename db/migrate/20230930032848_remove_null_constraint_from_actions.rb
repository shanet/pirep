class RemoveNullConstraintFromActions < ActiveRecord::Migration[7.0]
  def change
    change_column_null :actions, :actionable_id, true # rubocop:disable Rails/BulkChangeTable
    change_column_null :actions, :actionable_type, true
  end
end
