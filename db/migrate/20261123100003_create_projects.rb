class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    # An RFQ project. It also holds the bidder list (merged 1:1 in schema v3).
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :erp_rfq
      t.text :scope
      t.string :client_name
      t.string :client_area
      t.decimal :budget_amount, precision: 14, scale: 2
      t.string :budget_currency, null: false, default: "JPY"
      t.string :status, null: false, default: "draft"
      t.text :buyer_comment

      t.timestamps
    end
    add_index :projects, :status
  end
end
