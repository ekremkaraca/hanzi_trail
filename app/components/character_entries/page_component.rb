module CharacterEntries
  class PageComponent < ViewComponent::Base
    def initialize(character_entry:, flashcard_characters:)
      @character_entry = character_entry
      @flashcard_characters = flashcard_characters
    end

    private

    attr_reader :character_entry, :flashcard_characters

    # Deleting an entry any card still needs corrupts those cards irreversibly
    # (CharacterEntry#deletable?), so the affordance is hidden rather than
    # offering an action the controller will refuse.
    def deletable?
      character_entry.deletable?
    end
  end
end
