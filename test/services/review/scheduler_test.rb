require "test_helper"

class Review::SchedulerTest < ActiveSupport::TestCase
  setup do
    @flashcard = flashcards(:network)
    @initial_review_count = @flashcard.review_attempts.count
  end

  test "call successfully updates the flashcard and creates a review attempt" do
    scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "good")

    # Freeze time so we can precisely test the timestamp update
    freeze_time do
      assert_difference("ReviewAttempt.count", 1) do
        scheduler.call
      end

      @flashcard.reload

      # Verify the flashcard was pushed into the future
      assert @flashcard.next_review_at > Time.current

      # Verify the attempt was logged correctly
      latest_attempt = @flashcard.review_attempts.last
      assert_equal "good", latest_attempt.rating
    end
  end

  test "call rolls back everything if creating the review attempt fails" do
    scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "good")

    original_due_date = @flashcard.next_review_at
    invalid_attempt = ReviewAttempt.new(flashcard: @flashcard, rating: "good")
    failing_attempts = Object.new
    failing_attempts.define_singleton_method(:create!) do |**|
      raise ActiveRecord::RecordInvalid, invalid_attempt
    end

    # Replace only this instance's association writer to simulate an audit-row failure.
    @flashcard.define_singleton_method(:review_attempts) { failing_attempts }

    # Ensure neither the Flashcard nor the ReviewAttempt is saved
    assert_no_difference("ReviewAttempt.count") do
      assert_raises(ActiveRecord::RecordInvalid) do
        scheduler.call
      end
    end

    @flashcard.reload
    assert_equal original_due_date, @flashcard.next_review_at
  end

  test "call rejects invalid ratings before mutating review state" do
    scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "invalid_rating")
    original_due_date = @flashcard.next_review_at

    assert_no_difference("ReviewAttempt.count") do
      # Invalid ratings are input errors, not transaction rollback scenarios.
      assert_raises(ArgumentError) do
        scheduler.call
      end
    end

    @flashcard.reload
    assert_equal original_due_date, @flashcard.next_review_at
  end
end
