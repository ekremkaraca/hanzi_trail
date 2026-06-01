require "test_helper"

class FlashcardCharacterTest < ActiveSupport::TestCase
  test "requires non-negative position" do
    link = FlashcardCharacter.new(
      flashcard: flashcards(:network),
      character_entry: character_entries(:one),
      position: -1
    )

    assert_not link.valid?
  end
end
