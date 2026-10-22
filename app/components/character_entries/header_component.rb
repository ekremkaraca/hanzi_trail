module CharacterEntries
  class HeaderComponent < ViewComponent::Base
    def initialize(character_entry:)
      @character_entry = character_entry
    end

    private

    attr_reader :character_entry

    def pinyin_text
      character_entry.primary_pinyin.presence || "Pinyin not added yet"
    end

    # Polyphonic characters carry the primary reading first and the
    # alternatives after it ("cháng,zhǎng"); the alternates are shown
    # as a secondary line rather than a comma list.
    def alternate_pinyin_text
      alternates = character_entry.alternate_pinyin
      return if alternates.empty?

      "also #{alternates.join(", ")}"
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
