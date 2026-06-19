require "test_helper"

module Flashcards
  module Show
    class DetailGridComponentTest < ViewComponent::TestCase
      test "shows overdue text when next_review_at is in the past" do
        flashcard = flashcards(:overdue_review)

        render_inline(DetailGridComponent.new(flashcard: flashcard))

        assert_text "Overdue by"
      end

      test "shows due-in text when next_review_at is in the future" do
        flashcard = flashcards(:algorithm)

        render_inline(DetailGridComponent.new(flashcard: flashcard))

        assert_text "Due in"
      end
    end
  end
end
