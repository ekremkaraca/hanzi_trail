class CharacterEntry < ApplicationRecord
  # Where a pinyin value came from: "manual" (a curator typed it) or
  # "dictionary" (imported from a pinyin dictionary file). NULL means
  # unknown provenance — entries curated before this column existed —
  # and those are never overwritten by an import.
  PINYIN_SOURCES = %w[manual dictionary].freeze

  has_many :flashcard_characters, dependent: :destroy
  has_many :flashcards, through: :flashcard_characters

  validates :character, presence: true, uniqueness: true, length: { is: 1 }
  validates :pinyin_source, inclusion: { in: PINYIN_SOURCES }, allow_nil: true

  # A curator editing the pinyin owns that value from then on, so it is
  # marked manual and a later dictionary re-import leaves it alone. The
  # importer writes both columns with update_columns (no callbacks), so
  # imported values keep their dictionary provenance.
  before_validation :mark_pinyin_manual, if: :will_save_change_to_pinyin?

  # The dictionary stores readings comma-separated, primary first
  # ("cháng,zhǎng"). These helpers split that for display.
  def pinyin_readings
    pinyin.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def primary_pinyin
    pinyin_readings.first
  end

  def alternate_pinyin
    pinyin_readings.drop(1)
  end

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

  private

  def mark_pinyin_manual
    self.pinyin_source = "manual"
  end
end
