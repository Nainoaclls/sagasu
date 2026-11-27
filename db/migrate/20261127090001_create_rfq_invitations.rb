class CreateRfqInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :rfq_invitations do |t|
      t.references :approval, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      # Who marked the invitation as sent; null until then.
      t.references :user, null: true, foreign_key: true
      t.datetime :sent_at

      t.timestamps
    end
    add_index :rfq_invitations, [:approval_id, :supplier_id], unique: true
  end
end
