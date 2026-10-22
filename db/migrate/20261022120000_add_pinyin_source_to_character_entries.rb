class AddPinyinSourceToCharacterEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :character_entries, :pinyin_source, :string
    add_index :character_entries, :pinyin_source
    # NULL stays allowed: entries curated before this column existed
    # have unknown provenance and are never overwritten.
    add_check_constraint :character_entries,
      "pinyin_source IS NULL OR pinyin_source IN ('manual', 'dictionary')",
      name: "character_entries_pinyin_source_check"
  end
end
