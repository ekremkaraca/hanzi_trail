require "test_helper"

module Flashcards
  module Show
    class HeroComponentTest < ViewComponent::TestCase
      test "uses phrase size class for four or more characters" do
        flashcard = flashcards(:network)
        flashcard.character = "四个汉字"

        render_inline(HeroComponent.new(flashcard: flashcard))

        assert_selector ".flashcard-show-symbol.symbol--phrase"
      end

      test "uses long size class for three characters" do
        flashcard = flashcards(:network)
        flashcard.character = "三个字"

        render_inline(HeroComponent.new(flashcard: flashcard))

        assert_selector ".flashcard-show-symbol.symbol--long"
      end

      test "uses no length modifier for one or two characters" do
        flashcard = flashcards(:network)
        flashcard.character = "网"

        render_inline(HeroComponent.new(flashcard: flashcard))

        assert_selector ".flashcard-show-symbol"
        assert_no_selector ".flashcard-show-symbol.symbol--long"
        assert_no_selector ".flashcard-show-symbol.symbol--phrase"
      end
    end
  end
end
