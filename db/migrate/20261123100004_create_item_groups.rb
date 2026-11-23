class CreateItemGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :item_groups do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :ai_reason
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :item_groups, [:project_id, :position]
  end
end
