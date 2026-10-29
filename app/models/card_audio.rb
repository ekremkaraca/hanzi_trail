class CardAudio < ApplicationRecord
  belongs_to :flashcard

  validates :key, presence: true, uniqueness: true
  validates :bytes, presence: true

  # Re-rendering the same key replaces bytes in place; a voice change
  # gets a fresh key instead, so objects are immutable per key.
  def self.upsert_with_key!(flashcard, key, mp3_bytes)
    find_or_initialize_by(flashcard: flashcard, key: key).tap do |audio|
      audio.update!(bytes: mp3_bytes)
    end
  end
end
