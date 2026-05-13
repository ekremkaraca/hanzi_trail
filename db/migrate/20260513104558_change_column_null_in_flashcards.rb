class ChangeColumnNullInFlashcards < ActiveRecord::Migration[8.1]
  def change
    change_column_null :flashcards, :character, false
    change_column_null :flashcards, :pinyin, false
    change_column_null :flashcards, :meaning, false
  end
end
