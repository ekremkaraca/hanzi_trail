require "test_helper"

class Review::QueueTest < ActiveSupport::TestCase
  setup do
    Flashcard.update_all(next_review_at: 1.day.from_now)
  end

  test "next_card returns nil when no cards are due" do
    queue = Review::Queue.new(filters: {}, session: {})

    assert_nil queue.next_card
  end

  test "remaining_count returns zero when no cards are due" do
    queue = Review::Queue.new(filters: {}, session: {})

    assert_equal 0, queue.remaining_count
  end

  test "next_card returns a due flashcard" do
    due_card = flashcards(:network)
    due_card.update!(next_review_at: 1.hour.ago)

    queue = Review::Queue.new(filters: {}, session: {})

    assert_equal due_card, queue.next_card
  end

  test "next_card returns earliest due flashcard first" do
    earlier_card = flashcards(:network)
    later_card = flashcards(:hsk_one)

    earlier_card.update!(next_review_at: 2.hours.ago)
    later_card.update!(next_review_at: 1.hour.ago)

    queue = Review::Queue.new(filters: {}, session: {})

    assert_equal earlier_card, queue.next_card
  end

  test "remaining_count counts only due cards" do
    flashcards(:network).update!(next_review_at: 2.hours.ago)
    flashcards(:hsk_one).update!(next_review_at: 1.hour.ago)
    flashcards(:future_review).update!(next_review_at: 1.day.from_now)

    queue = Review::Queue.new(filters: {}, session: {})

    assert_equal 2, queue.remaining_count
  end

  test "next_card respects the source filter" do
    hsk_card = flashcards(:hsk_one)
    curated_card = flashcards(:network)

    hsk_card.update!(source: "hsk", next_review_at: 1.hour.ago)
    curated_card.update!(source: "curated", next_review_at: 2.hours.ago)

    queue = Review::Queue.new(filters: { source: "hsk" }, session: {})

    assert_equal hsk_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end

  test "next_card respects the category filter" do
    technical_card = flashcards(:network)
    other_card = flashcards(:hsk_one)

    technical_card.update!(category: "technical", next_review_at: 1.hour.ago)
    other_card.update!(category: "hsk", next_review_at: 2.hours.ago)

    queue = Review::Queue.new(filters: { category: "technical" }, session: {})

    assert_equal technical_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end

  test "next_card respects the story status filter" do
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

    queue = Review::Queue.new(filters: { story_status: "missing" }, session: {})

    assert_equal missing_story_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end

  test "next_card respects the short story pseudo filter" do
    short_story_card = flashcards(:network)
    missing_story_card = flashcards(:hsk_one)

    short_story_card.update!(
      story: "short",
      story_status: "curated",
      next_review_at: 1.hour.ago
    )

    missing_story_card.update!(
      story: "",
      story_status: "missing",
      next_review_at: 2.hours.ago
    )

    queue = Review::Queue.new(filters: { story_status: "short" }, session: {})

    assert_equal short_story_card, queue.next_card
    assert_equal 1, queue.remaining_count
  end

  test "empty_state_message returns natural empty message when no cards are due overall" do
    Flashcard.update_all(next_review_at: 1.year.from_now)

    queue = Review::Queue.new(filters: {}, session: {})

    assert_nil queue.next_card
    assert_equal "No cards due!", queue.empty_state_message
  end

  test "empty_state_message returns filter warning when filters are too strict" do
    queue = Review::Queue.new(filters: { source: "non_existent_source" }, session: {})

    assert_nil queue.next_card
    assert_equal "No cards match your current filters.", queue.empty_state_message
  end
end
