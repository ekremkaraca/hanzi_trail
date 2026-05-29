require "test_helper"

class ReviewAttemptTest < ActiveSupport::TestCase
  test "valid with flashcard and rating" do
    attempt = ReviewAttempt.new(
      flashcard: flashcards(:network),
      rating: "good"
    )

    assert attempt.valid?, attempt.errors.full_messages.to_sentence
    assert attempt.reviewed_at.present?
  end

  test "requires valid rating" do
    attempt = ReviewAttempt.new(
      flashcard: flashcards(:network),
      rating: "perfect"
    )

    assert_not attempt.valid?
    assert_includes attempt.errors[:rating], "is not included in the list"
  end
end
