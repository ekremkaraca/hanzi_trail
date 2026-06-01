require "test_helper"

class CharacterLinkerTest < ActiveSupport::TestCase
  test "links flashcard to individual characters" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    assert_difference("CharacterEntry.count", 2) do
      CharacterLinker.call(card)
    end

    assert_equal [ "网", "络" ], card.character_entries.order("flashcard_characters.position").pluck(:character)
  end

  test "does not duplicate links" do
    card = flashcards(:network)

    CharacterLinker.call(card)

    assert_no_difference("FlashcardCharacter.count") do
      CharacterLinker.call(card)
    end
  end
end
