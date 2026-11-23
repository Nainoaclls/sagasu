class CreateApprovals < ActiveRecord::Migration[8.1]
  def change
    # One row per submission: the approval history of a bidder list.
    create_table :approvals do |t|
      t.references :project, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.text :comment
      t.datetime :decided_at
      # Frozen copy of the groups and selected suppliers at submission time
      t.jsonb :snapshot, null: false, default: {}

      t.timestamps
    end
    add_index :approvals, [:approver_id, :status]
  end
end
