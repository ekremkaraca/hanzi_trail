class AddUnderstandingFieldsToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :components, :text
    add_column :flashcards, :literal_meaning, :text
    add_column :flashcards, :mnemonic, :text
    add_column :flashcards, :usage_note, :text
  end
end
