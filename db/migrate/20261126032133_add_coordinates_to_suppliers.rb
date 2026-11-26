class AddCoordinatesToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :latitude, :float
    add_column :suppliers, :longitude, :float
    add_index :suppliers, %i[latitude longitude]
  end
end
