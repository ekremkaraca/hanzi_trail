class AddSourceAndHskLevelToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :source, :string
    add_column :flashcards, :hsk_level, :string

    add_index :flashcards, :source
    add_index :flashcards, :hsk_level
    add_index :flashcards, [ :source, :hsk_level ]
  end
end
