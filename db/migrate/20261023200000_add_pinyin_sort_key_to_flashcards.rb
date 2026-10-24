class AddPinyinSortKeyToFlashcards < ActiveRecord::Migration[8.1]
  # Tone marks (ā ē ī ō ū ǎ ǐ ǒ ǔ ...) sort after plain Latin letters in the
  # default collation, so ORDER BY pinyin reads wrong ("ba" after "ze").
  # The browse order uses this normalized, toneless key instead. The
  # normalization lambda is duplicated from Flashcard.normalize_pinyin on
  # purpose: migrations must stay runnable against future model changes.
  NORMALIZE = lambda { |pinyin|
    pinyin.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.strip
  }

  def up
    add_column :flashcards, :pinyin_sort_key, :string, null: false, default: ""
    add_index :flashcards, :pinyin_sort_key

    Flashcard.reset_column_information
    Flashcard.select(:id, :pinyin).find_each do |card|
      Flashcard.where(id: card.id).update_all(pinyin_sort_key: NORMALIZE.call(card.pinyin))
    end
  end

  def down
    remove_index :flashcards, :pinyin_sort_key
    remove_column :flashcards, :pinyin_sort_key
    Flashcard.reset_column_information
  end
end
