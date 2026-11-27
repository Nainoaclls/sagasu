class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :kind, null: false
      t.datetime :read_at

      t.timestamps
    end
    add_index :notifications, %i[user_id read_at]
  end
end
