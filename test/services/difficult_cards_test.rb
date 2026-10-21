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

  test "ignores difficult ratings older than the window" do
    freeze_time do
      ReviewAttempt.delete_all

      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "again",
        reviewed_at: Time.current
      )

      # This struggle is older than the window, so
      # the card is no longer counted as difficult.
      ReviewAttempt.create!(
        flashcard: flashcards(:algorithm),
        rating: "hard",
        reviewed_at: 91.days.ago
      )

      cards = DifficultCards.call(limit: 10).to_a

      assert_equal [ flashcards(:network) ], cards
      assert_equal 1, cards.first.difficult_review_count.to_i
    end
  end
end
