class CreateCharacterEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :character_entries do |t|
      t.string :character, null: false
      t.string :pinyin
      t.string :meaning
      t.string :radical
      t.text :notes

      t.index :character, unique: true

      t.timestamps
    end
  end
end
