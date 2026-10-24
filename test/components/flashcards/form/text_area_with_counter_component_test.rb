require "test_helper"

module Flashcards
  module Form
    class TextAreaWithCounterComponentTest < ViewComponent::TestCase
      test "story field wires the vendored character-counter with code-point counting" do
        # Rendered through the owning form so the FormBuilder comes from
        # form_with, not a hand-built one.
        render_inline(
          Flashcards::FormComponent.new(flashcard: flashcards(:network))
        )

        # Every counter field shares the same wiring contract.
        assert_selector "div[data-controller='character-counter'][data-character-counter-count-unit-value='code-points']", count: 5

        story = "textarea[name='flashcard[story]'][data-character-counter-target='input']"
        assert_selector story + "[maxlength='2000']"
        assert_selector "span[data-character-counter-target='counter']", count: 5
        assert_text "/ 2000"
      end
    end
  end
end
