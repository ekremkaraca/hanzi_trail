require "test_helper"

module Flashcards
  module Show
    class PageComponentTest < ViewComponent::TestCase
      test "renders never when card has not been reviewed" do
        flashcard = flashcards(:network)
        flashcard.review_attempts.destroy_all

        render_inline(PageComponent.new(flashcard: flashcard, session: {}))

        assert_text "Last reviewed:"
        assert_text "Never"
      end

      test "renders active review return link from session" do
        render_inline(
          PageComponent.new(
            flashcard: flashcards(:network),
            session: { review_return_to: "/review?source=hsk" }
          )
        )

        assert_selector "a[href='/review?source=hsk']", text: "Return to Active Review"
      end
    end
  end
end
