class NormalizeFlashcardSource < ActiveRecord::Migration[8.1]
  def up
    Flashcard.where(source: [ nil, "" ]).update_all(source: "curated")

    change_column_default :flashcards, :source, "curated"
    change_column_null :flashcards, :source, false
  end

  def down
    change_column_null :flashcards, :source, true
    change_column_default :flashcards, :source, nil
  end
end
