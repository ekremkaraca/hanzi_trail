module Review
  class Scheduler
    attr_reader :flashcard, :rating

    def initialize(flashcard:, rating:)
      @flashcard = flashcard
      @rating = rating
    end

    def call
      # Preserve the old model guard so bad ratings never mutate the card.
      raise ArgumentError, "Invalid rating" unless Flashcard::REVIEW_RATINGS.include?(rating)

      flashcard.with_lock do
        # Keep the not-due check inside the lock to avoid double-review races.
        raise Flashcard::CardNotDueError unless flashcard.next_review_at <= Time.current

        reviewed_at = Time.current

        # Update every review-state field the previous model method updated.
        flashcard.update!(
          difficulty: rating,
          review_count: flashcard.review_count + 1,
          next_review_at: next_review_at(reviewed_at)
        )

        # Store the audit row in the same transaction as the card state change.
        flashcard.review_attempts.create!(
          flashcard: flashcard,
          rating: rating,
          reviewed_at: reviewed_at
        )
      end
    end

    private

    def next_review_at(reviewed_at)
      # Match Flashcard#schedule_next_review! intervals exactly during extraction.
      intervals.fetch(rating).since(reviewed_at)
    end

    def intervals
      {
        "again" => 1.minute,
        "hard" => 1.day,
        "good" => 3.days,
        "easy" => 7.days
      }
    end
  end
end
