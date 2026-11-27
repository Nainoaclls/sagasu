class CreateProjectMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :project_messages do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
