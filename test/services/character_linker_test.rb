require "test_helper"

class CharacterLinkerTest < ActiveSupport::TestCase
  test "links flashcard to individual characters" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    assert_difference("FlashcardCharacter.count", 2) do
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

  test "updates links when flashcard character changes" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    CharacterLinker.call(card)

    card.update!(character: "中国")
    CharacterLinker.call(card)

    assert_equal [ "中", "国" ],
      card.flashcard_characters
          .includes(:character_entry)
          .order(:position)
          .map { |link| link.character_entry.character }
  end

  test "does not duplicate links when run repeatedly" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    CharacterLinker.call(card)

    assert_no_difference("FlashcardCharacter.count") do
      CharacterLinker.call(card)
    end
  end

  test "skips repeated characters within a flashcard" do
    card = Flashcard.create!(
      character: "人人",
      pinyin: "rénrén",
      meaning: "everyone"
    )

    assert_nothing_raised do
      CharacterLinker.call(card)
    end

    assert_equal [ "人" ], card.character_entries.order("flashcard_characters.position").pluck(:character)
    assert_equal 1, card.flashcard_characters.count
  end
end
