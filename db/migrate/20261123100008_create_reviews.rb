class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      # Required only when visibility is "project"
      t.references :project, foreign_key: true
      t.integer :rating, null: false
      t.text :comment, null: false
      t.string :visibility, null: false, default: "organization"
      t.boolean :ai_usable, null: false, default: true
      # Anti-blacklisting: a single observation starts unverified
      t.string :status, null: false, default: "unverified"

      t.timestamps
    end
    add_check_constraint :reviews, "rating BETWEEN 1 AND 5", name: "reviews_rating_range"
  end
end
