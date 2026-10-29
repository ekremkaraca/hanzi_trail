class CreateCardAudios < ActiveRecord::Migration[8.1]
  def change
    # Audio bytes live in their own table so flashcard queries (the
    # review queue reads 20+ cards per page) never drag ~11KB blobs along.
    create_table :card_audios do |t|
      t.references :flashcard, null: false, foreign_key: true
      t.string :key, null: false
      t.binary :bytes, null: false

      t.timestamps
    end

    # One key is immutable per (card, voice); a voice re-render gets a
    # fresh key, so key is the natural unique handle for serving.
    add_index :card_audios, :key, unique: true
  end
end
