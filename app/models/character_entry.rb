class CharacterEntry < ApplicationRecord
  has_many :flashcard_characters, dependent: :destroy
  has_many :flashcards, through: :flashcard_characters

  validates :character, presence: true, uniqueness: true

  def flashcards_count
    flashcards.count
  end
end
