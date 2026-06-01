class CreateFlashcardCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :flashcard_characters do |t|
      t.references :flashcard, null: false, foreign_key: true
      t.references :character_entry, null: false, foreign_key: true
      t.integer :position, null: false

      t.index [ :flashcard_id, :character_entry_id ], unique: true
      t.index [ :flashcard_id, :position ], unique: true

      t.timestamps
    end
  end
end
