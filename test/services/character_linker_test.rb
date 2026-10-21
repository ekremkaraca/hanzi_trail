require "test_helper"

class CharacterLinkerTest < ActiveSupport::TestCase
  test "links flashcard to individual characters" do
    # The Flashcard after_save callback now runs the linker on create.
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    assert_equal 2, card.flashcard_characters.count

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

  test "relink recovers when a concurrent process inserts the same character" do
    card = flashcards(:network) # 网, whose entry already exists

    # Simulate another request winning the insert race for
    # 网: the SELECT misses and the INSERT hits the unique
    # index, which must not poison the relink transaction.
    # (Minitest 6 dropped Object#stub, so swap the finder
    # explicitly and restore it afterwards.)
    finder = CharacterEntry.method(:find_or_create_by!)
    CharacterEntry.define_singleton_method(:find_or_create_by!) do |_attrs|
      raise ActiveRecord::RecordNotUnique.new("stub insert race")
    end

    begin
      assert_nothing_raised { CharacterLinker.call(card) }
    ensure
      CharacterEntry.define_singleton_method(:find_or_create_by!, finder)
    end

    assert_equal [ "网" ], card.character_entries.order("flashcard_characters.position").pluck(:character)
  end

  test "prunes entries that only this card used after a relink" do
    card = Flashcard.create!(
      character: "田由",
      pinyin: "tiányóu",
      meaning: "field and reason"
    )

    assert_not_nil CharacterEntry.find_by(character: "田")
    assert_not_nil CharacterEntry.find_by(character: "由")

    card.update!(character: "中国")

    # 田 and 由 lost their only links and no other card's
    # character string references them, so the relink prunes
    # them while wiring the new characters.
    assert_nil CharacterEntry.find_by(character: "田")
    assert_nil CharacterEntry.find_by(character: "由")
    assert_not_nil CharacterEntry.find_by(character: "中")
    assert_not_nil CharacterEntry.find_by(character: "国")
  end
end
