require "test_helper"

class ReviewQueueTest < ActiveSupport::TestCase
  setup do
    Flashcard.update_all(next_review_at: 1.day.from_now)
  end

  test "next_card returns nil when no cards are due" do
    queue = ReviewQueue.new

    assert_nil queue.next_card
  end

  test "remaining_count returns zero when no cards are due" do
    queue = ReviewQueue.new

    assert_equal 0, queue.remaining_count
  end

  test "next_card returns a due flashcard" do
    due_card = flashcards(:network)
    due_card.update!(next_review_at: 1.hour.ago)

    queue = ReviewQueue.new

    assert_equal due_card, queue.next_card
  end

  test "next_card returns earliest due flashcard first" do
    earlier_card = flashcards(:network)
    later_card = flashcards(:hsk_one)

    earlier_card.update!(next_review_at: 2.hours.ago)
    later_card.update!(next_review_at: 1.hour.ago)

    queue = ReviewQueue.new

    assert_equal earlier_card, queue.next_card
  end

  test "remaining_count counts only due cards" do
    flashcards(:network).update!(next_review_at: 2.hours.ago)
    flashcards(:hsk_one).update!(next_review_at: 1.hour.ago)
    flashcards(:future_review).update!(next_review_at: 1.day.from_now)

    queue = ReviewQueue.new

    assert_equal 2, queue.remaining_count
  end

  test "queue respects provided scope" do
    curated_card = flashcards(:network)
    hsk_card = flashcards(:hsk_one)

    curated_card.update!(
      source: "curated",
      next_review_at: 2.hours.ago
    )

    hsk_card.update!(
      source: "hsk",
      next_review_at: 1.hour.ago
    )

    queue = ReviewQueue.new(scope: Flashcard.by_source("hsk"))

    assert_equal hsk_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end

  test "queue scope can filter by story status" do
    missing_story_card = flashcards(:hsk_one)
    curated_story_card = flashcards(:network)

    missing_story_card.update!(
      story_status: "missing",
      next_review_at: 2.hours.ago
    )

    curated_story_card.update!(
      story_status: "curated",
      next_review_at: 1.hour.ago
    )

    queue = ReviewQueue.new(scope: Flashcard.by_story_status("missing"))

    assert_equal missing_story_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end
end
