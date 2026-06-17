module CharacterEntries
  class RelatedWordsComponent < ViewComponent::Base
    def initialize(flashcard_characters:)
      @flashcard_characters = flashcard_characters
    end

    private

    attr_reader :flashcard_characters

    def any_links?
      flashcard_characters.any?
    end

    def cards
      flashcard_characters.map(&:flashcard)
    end

    def flashcard_path(card)
      helpers.flashcard_path(card)
    end
  end
end
