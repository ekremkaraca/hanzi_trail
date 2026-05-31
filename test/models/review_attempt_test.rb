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

  test "today returns attempts reviewed today" do
    today_attempt = review_attempts(:one)
    old_attempt = ReviewAttempt.create!(
      flashcard: flashcards(:network),
      rating: "good",
      reviewed_at: 2.days.ago
    )

    assert_includes ReviewAttempt.today, today_attempt
    refute_includes ReviewAttempt.today, old_attempt
  end

  test "recent scope orders by reviewed_at descending" do
    old = ReviewAttempt.create!(flashcard: flashcards(:network), rating: "good", reviewed_at: 2.days.ago)
    recent = ReviewAttempt.create!(flashcard: flashcards(:network), rating: "good", reviewed_at: 1.hour.ago)

    assert_equal [ review_attempts(:one), recent, old ], ReviewAttempt.recent.to_a
  end

  test "by_rating scope filters by rating" do
    good = review_attempts(:one)
    hard = ReviewAttempt.create!(flashcard: flashcards(:network), rating: "hard")

    assert_includes ReviewAttempt.by_rating("good"), good
    refute_includes ReviewAttempt.by_rating("good"), hard
  end

  test "requires a flashcard association" do
    attempt = ReviewAttempt.new(rating: "good")

    assert_not attempt.valid?
    assert_includes attempt.errors[:flashcard], "must exist"
  end

  test "sets reviewed_at before validation on create" do
    attempt = ReviewAttempt.create!(flashcard: flashcards(:network), rating: "good")

    assert attempt.reviewed_at.present?
  end

  test "destroying flashcard destroys its review attempts" do
    attempt = review_attempts(:one)

    flashcards(:network).destroy

    assert_raises(ActiveRecord::RecordNotFound) { attempt.reload }
  end
end
