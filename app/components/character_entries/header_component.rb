module CharacterEntries
  class HeaderComponent < ViewComponent::Base
    def initialize(character_entry:)
      @character_entry = character_entry
    end

    private

    attr_reader :character_entry

    def pinyin_text
      character_entry.pinyin.presence || "Pinyin not added yet"
    end

    def meaning_text
      character_entry.meaning.presence || "Meaning not added yet"
    end

    def show_radical?
      character_entry.radical.present?
    end

    def show_notes?
      character_entry.notes.present?
    end

    def formatted_notes
      helpers.simple_format(character_entry.notes)
    end
  end
end
