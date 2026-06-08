require "test_helper"

class DifficultCardsTest < ActiveSupport::TestCase
  test "returns cards ordered by difficult review count" do
    freeze_time do
      ReviewAttempt.delete_all

      3.times do
        ReviewAttempt.create!(
          flashcard: flashcards(:network),
          rating: "again",
          reviewed_at: Time.current
        )
      end

      ReviewAttempt.create!(
        flashcard: flashcards(:algorithm),
        rating: "hard",
        reviewed_at: Time.current
      )

      ReviewAttempt.create!(
        flashcard: flashcards(:hsk_one),
        rating: "good",
        reviewed_at: Time.current
      )

      cards = DifficultCards.call(limit: 10).to_a

      assert_equal [ flashcards(:network), flashcards(:algorithm) ], cards
      assert_equal 3, cards.first.difficult_review_count.to_i
      assert_equal 1, cards.second.difficult_review_count.to_i
    end
  end
end
