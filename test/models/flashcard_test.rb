require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
  test "valid with required fields" do
    card = Flashcard.new(
      character: "网",
      pinyin: "wǎng",
      meaning: "network"
    )

    assert card.valid?
  end
end
