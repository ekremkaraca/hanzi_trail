module CharacterEntries
  class FormComponent < ViewComponent::Base
    def initialize(character_entry:)
      @character_entry = character_entry
    end

    private

    attr_reader :character_entry

    def has_errors?
      character_entry.errors.any?
    end

    def error_messages
      character_entry.errors.full_messages
    end
  end
end
