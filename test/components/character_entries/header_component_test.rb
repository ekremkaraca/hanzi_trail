require "test_helper"

module CharacterEntries
  class HeaderComponentTest < ViewComponent::TestCase
    test "displays character, pinyin, and meaning" do
      character_entry = character_entries(:one)
      character_entry.pinyin = "wǎng"
      character_entry.meaning = "network"

      render_inline(HeaderComponent.new(character_entry: character_entry))

      assert_text "网"
      assert_text "wǎng"
      assert_text "network"
    end

    test "shows radical when present" do
      character_entry = character_entries(:one)
      character_entry.radical = "冂"

      render_inline(HeaderComponent.new(character_entry: character_entry))

      assert_text "冂"
    end

    test "shows formatted notes when present" do
      character_entry = character_entries(:one)
      character_entry.notes = "A note about this character."

      render_inline(HeaderComponent.new(character_entry: character_entry))

      assert_text "A note about this character."
    end

    test "provides fallback text when pinyin is missing" do
      character_entry = character_entries(:one)
      character_entry.pinyin = nil

      render_inline(HeaderComponent.new(character_entry: character_entry))

      assert_text "Pinyin not added yet"
    end

    test "provides fallback text when meaning is missing" do
      character_entry = character_entries(:one)
      character_entry.meaning = nil

      render_inline(HeaderComponent.new(character_entry: character_entry))

      assert_text "Meaning not added yet"
    end
  end
end
