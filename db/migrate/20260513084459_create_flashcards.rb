class CreateFlashcards < ActiveRecord::Migration[8.1]
  def change
    create_table :flashcards do |t|
      t.string :character
      t.string :pinyin
      t.string :meaning
      t.text :story
      t.string :category
      t.string :difficulty, null: false, default: "new"
      t.datetime :next_review_at, null: false
      t.integer :review_count, null: false, default: 0

      t.timestamps
    end
  end
end
