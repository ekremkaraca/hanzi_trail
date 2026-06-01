class CharacterLinker
  def self.call(flashcard)
    new(flashcard).call
  end

  def initialize(flashcard)
    @flashcard = flashcard
  end

  def call
    flashcard.character.each_char.with_index do |char, index|
      entry = CharacterEntry.find_or_create_by!(character: char)

      FlashcardCharacter.find_or_create_by!(
        flashcard: flashcard,
        character_entry: entry
      ) do |link|
        link.position = index
      end
    end
  end

  private

  attr_reader :flashcard
end
