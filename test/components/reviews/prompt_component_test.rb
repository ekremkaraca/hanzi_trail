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
        text: "How to add one", visible: :all
    end

    test "names the hint as the description of the Speak button" do
      render_inline(PromptComponent.new(flashcard: flashcards(:network), show_pinyin: false))

      # The hint ships hidden, so the reference only resolves once the
      # controller reveals it — which is when the disabled button needs it.
      assert_selector "button[data-review-target='speakButton'][aria-describedby='review-voice-hint']"
      assert_selector "#review-voice-hint[hidden]", visible: :all
    end

    test "lists each platform as a labelled row instead of a centred bullet" do
      render_inline(PromptComponent.new(flashcard: flashcards(:network), show_pinyin: false))

      assert_selector "#review-voice-hint details dl", count: 1, visible: :all
      %w[macOS Windows Linux].each do |platform|
        assert_selector "#review-voice-hint dt", text: platform, visible: :all
      end
      assert_no_selector "#review-voice-hint ul", visible: :all
    end
  end
end
