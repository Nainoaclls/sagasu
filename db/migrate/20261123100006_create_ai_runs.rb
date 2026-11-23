class CreateAiRuns < ActiveRecord::Migration[8.1]
  def change
    # Audit trail of every AI call: what was asked, which model, what came back.
    create_table :ai_runs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :model
      t.text :prompt
      t.text :output
      t.string :status, null: false, default: "succeeded"

      t.timestamps
    end
    add_index :ai_runs, :kind
  end
end
