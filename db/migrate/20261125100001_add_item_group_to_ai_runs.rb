class AddItemGroupToAiRuns < ActiveRecord::Migration[8.1]
  def change
    # Which group a supplier-suggestion run was for (shows "Sagasu is searching…" on the right card).
    # Nullified when the group is deleted by a regroup: the run stays in the audit trail.
    add_reference :ai_runs, :item_group, foreign_key: { on_delete: :nullify }
  end
end
