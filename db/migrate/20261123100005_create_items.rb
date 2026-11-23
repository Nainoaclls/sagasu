class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :project, null: false, foreign_key: true
      # nil until the buyer groups the materials (AI or manual)
      t.references :item_group, foreign_key: { on_delete: :nullify }
      t.string :erp_material
      t.string :description, null: false
      t.decimal :quantity, precision: 14, scale: 3
      t.string :unit_of_measure

      t.timestamps
    end
  end
end
