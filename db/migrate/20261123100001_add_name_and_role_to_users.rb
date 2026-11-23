class AddNameAndRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    # buyer builds bidder lists, approver validates them
    add_column :users, :role, :string, null: false, default: "buyer"
    add_index :users, :role
  end
end
