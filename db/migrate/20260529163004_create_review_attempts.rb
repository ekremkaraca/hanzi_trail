class CreateReviewAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :review_attempts do |t|
      t.references :flashcard, null: false, foreign_key: true
      t.string :rating, null: false
      t.datetime :reviewed_at, null: false

      t.index :reviewed_at
      t.index [ :flashcard_id, :reviewed_at ]
      t.index :rating

      t.timestamps
    end
  end
end
