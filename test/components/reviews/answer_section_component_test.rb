require "test_helper"

module Reviews
  class AnswerSectionComponentTest < ViewComponent::TestCase
    test "renders story tab only when card has no optional answer sections" do
      flashcard = flashcards(:network)
      flashcard.update!(
        components: nil,
        literal_meaning: nil,
        mnemonic: nil,
        usage_note: nil
      )
      flashcard.character_entries.clear

      render_inline(AnswerSectionComponent.new(flashcard: flashcard))

      assert_selector "[role='tab']", text: "Story"
      assert_no_selector "[role='tab']", text: "Breakdown"
      assert_no_selector "[role='tab']", text: "Context"
    end

    test "renders optional answer tabs from component metadata" do
      flashcard = flashcards(:network)
      flashcard.update!(components: "网 = net", usage_note: "Used in internet terms.")

      render_inline(AnswerSectionComponent.new(flashcard: flashcard))

      assert_selector "[role='tab']", text: "Story"
      assert_selector "[role='tab']", text: "Breakdown"
      assert_selector "[role='tab']", text: "Context"
      assert_text "网 = net"
      assert_text "Used in internet terms."
    end
  end
end
