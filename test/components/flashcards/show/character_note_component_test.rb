require "test_helper"

module Flashcards
  module Show
    class CharacterNoteComponentTest < ViewComponent::TestCase
      test "renders when the attribute is present" do
        flashcard = flashcards(:network)
        flashcard.story = "A meaningful story."

        render_inline(CharacterNoteComponent.new(
          flashcard: flashcard,
          attribute: :story,
          title: "My Story"
        ))

        assert_text "My Story"
        assert_text "A meaningful story."
      end

      test "does not render when the attribute is blank" do
        flashcard = flashcards(:hsk_one)
        flashcard.story = ""

        render_inline(CharacterNoteComponent.new(
          flashcard: flashcard,
          attribute: :story,
          title: "My Story"
        ))

        assert_no_text "My Story"
      end
    end
  end
end
