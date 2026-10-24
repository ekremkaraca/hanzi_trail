require "test_helper"

module Reviews
  class AnswerSectionComponentTest < ViewComponent::TestCase
    # The section ships hidden (revealed by review_controller together
    # with the rating actions), so every assertion must opt out of
    # Capybara's visibility filtering.
    VISIBLE_ALL = { visible: :all }.freeze

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

      # Ships hidden; revealed together with the rating actions.
      assert_selector "div[data-review-target='answerSection'][hidden]", **VISIBLE_ALL

      assert_selector "[role='tab']", text: "Story", **VISIBLE_ALL
      assert_no_selector "[role='tab']", text: "Breakdown", **VISIBLE_ALL
      assert_no_selector "[role='tab']", text: "Context", **VISIBLE_ALL
    end

    test "renders optional answer tabs from component metadata" do
      flashcard = flashcards(:network)
      flashcard.update!(components: "网 = net", usage_note: "Used in internet terms.")

      render_inline(AnswerSectionComponent.new(flashcard: flashcard))

      assert_selector "[role='tab']", text: "Story", **VISIBLE_ALL
      assert_selector "[role='tab']", text: "Breakdown", **VISIBLE_ALL
      assert_selector "[role='tab']", text: "Context", **VISIBLE_ALL
      assert_text "网 = net"
      assert_text "Used in internet terms."
    end
  end
end
