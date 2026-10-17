class CharacterLinker
  def self.call(flashcard)
    new(flashcard).call
  end

  def initialize(flashcard)
    @flashcard = flashcard
  end

  def call
    FlashcardCharacter.transaction do
      # Capture the entries this card used before wiping its links, so any
      # entry that ends up with no remaining links can be pruned (entries are
      # derived data, not curator-owned records). Mirrors Flashcard's destroy
      # pruning so editing a card's character no longer orphans stale rows.
      previously_linked = flashcard.flashcard_characters.includes(:character_entry).map(&:character_entry)

      flashcard.flashcard_characters.destroy_all
      linked_characters = {}

      flashcard.character.each_char.with_index do |char, index|
        next if linked_characters.key?(char)

        entry = CharacterEntry.find_or_create_by!(character: char)

        flashcard.flashcard_characters.create!(
          character_entry: entry,
          position: index
        )

        linked_characters[char] = true
      end

      # Prune entries that lost all links during this relink. Guard with
      # deletable? so an entry still referenced by another card's character
      # string is never removed.
      previously_linked.each do |entry|
        entry.reload
        next unless entry.flashcard_characters.none?
        entry.destroy if entry.deletable?
      end
    end
  end

  private

  attr_reader :flashcard
end
