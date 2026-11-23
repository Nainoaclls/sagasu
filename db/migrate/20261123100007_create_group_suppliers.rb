class CreateGroupSuppliers < ActiveRecord::Migration[8.1]
  def change
    # A candidate supplier for one material group. Selected rows form the bidder list.
    create_table :group_suppliers do |t|
      t.references :item_group, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :ai_run, foreign_key: { on_delete: :nullify }
      t.boolean :ai_suggested, null: false, default: false
      t.text :ai_reason
      t.boolean :selected, null: false, default: false
      t.text :feedback_reason
      t.string :source, null: false, default: "search"
      # Schema v3 additions: what supports the match, and what the buyer still has to confirm
      t.string :evidence, array: true, null: false, default: []
      t.string :missing_info, array: true, null: false, default: []

      t.timestamps
    end
    add_index :group_suppliers, [:item_group_id, :supplier_id], unique: true
  end
end
