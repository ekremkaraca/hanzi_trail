class CharacterLinker
  def self.call(flashcard)
    new(flashcard).call
  end

  def initialize(flashcard)
    @flashcard = flashcard
  end

  def call
    FlashcardCharacter.transaction do
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
    end
  end

  private

  attr_reader :flashcard
end
