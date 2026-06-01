class FlashcardCharacter < ApplicationRecord
  belongs_to :flashcard
  belongs_to :character_entry

  validates :position,
    presence: true,
    numericality: {
      greater_than_or_equal_to: 0
    }
end
