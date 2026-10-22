require "test_helper"

module Reviews
  class PromptComponentTest < ViewComponent::TestCase
    test "wires the speak button to the review controller" do
      render_inline(PromptComponent.new(flashcard: flashcards(:network), show_pinyin: true))

      assert_selector "button[data-review-target='speakButton']"
      assert_selector "button[data-action='click->review#speak']", text: "Speak"
    end

    test "hides the voice hint until the controller reports no Mandarin voice" do
      render_inline(PromptComponent.new(flashcard: flashcards(:network), show_pinyin: false))

      # The hint ships hidden, so the assertions look past
      # Capybara's default visibility filter.
      assert_selector "[data-review-target='voiceHint'][hidden]", visible: false
      assert_selector "[data-review-target='voiceHint']",
        text: "This browser has no Mandarin voice", visible: false
      assert_selector "[data-review-target='voiceHint']",
        text: "How to add one", visible: false
    end
  end
end
