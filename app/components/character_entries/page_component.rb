module CharacterEntries
  class PageComponent < ViewComponent::Base
    def initialize(character_entry:, flashcard_characters:)
      @character_entry = character_entry
      @flashcard_characters = flashcard_characters
    end

    private

    attr_reader :character_entry, :flashcard_characters
  end
end
