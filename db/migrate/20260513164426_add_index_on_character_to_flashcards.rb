class AddIndexOnCharacterToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_index :flashcards, :character, unique: true
  end
end
