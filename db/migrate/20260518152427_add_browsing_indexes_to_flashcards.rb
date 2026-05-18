class AddBrowsingIndexesToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_index :flashcards, :story_status
    add_index :flashcards, :category
  end
end
