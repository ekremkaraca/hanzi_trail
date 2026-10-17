class CharacterEntry < ApplicationRecord
  has_many :flashcard_characters, dependent: :destroy
  has_many :flashcards, through: :flashcard_characters

  validates :character, presence: true, uniqueness: true, length: { is: 1 }

  # Character links are DERIVED from Flashcard#character by CharacterLinker, and
  # Flashcard only relinks when its character string changes. Deleting an entry
  # that a card still needs therefore strips that hanzi from the card's
  # breakdown permanently — the card's character never changes again, so the
  # relink callback never fires and no UI route can add the hanzi back (probed:
  # deleting 国 silently mutilated 8 cards). Only entries no card depends on
  # may be deleted; the rest are derived data, not curator-owned records.
  def required_by_cards
    Flashcard.where("character LIKE ?", "%#{Flashcard.sanitize_sql_like(character)}%")
  end

  def deletable?
    required_by_cards.none?
  end
end
