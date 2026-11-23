class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :country, null: false, default: "Japan"
      t.string :category, null: false
      t.string :tax_id
      t.string :erp_vendor_code
      t.string :website
      t.text :description

      # Evidence fields (schema v3 additions). nil means "unknown, to confirm".
      t.string :city
      t.string :prefecture
      t.string :delivery_areas, array: true, null: false, default: []
      t.integer :monthly_capacity
      t.string :capacity_unit
      t.integer :lead_time_days
      t.string :certifications, array: true, null: false, default: []
      t.string :source_url

      t.timestamps
    end
    add_index :suppliers, :category
    add_index :suppliers, :erp_vendor_code, unique: true, where: "erp_vendor_code IS NOT NULL"
  end
end
