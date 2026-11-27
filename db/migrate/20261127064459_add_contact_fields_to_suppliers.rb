class AddContactFieldsToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :contact_name, :string
    add_column :suppliers, :email, :string
    add_column :suppliers, :phone, :string
  end
end
