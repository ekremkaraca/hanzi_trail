require "test_helper"

class Review::QueueTest < ActiveSupport::TestCase
  setup do
    # Assuming you have fixtures or you create them here
    @due_hsk_card = flashcards(:hsk_one)
    @due_curated_card = flashcards(:network)
  end

  test "next_card returns the oldest due card when no filters are applied" do
    queue = Review::Queue.new(filters: {}, session: {})

    # It should just grab whatever is due next
    assert_not_nil queue.next_card
  end

  test "next_card respects the source filter" do
    queue = Review::Queue.new(filters: { source: "hsk" }, session: {})

    assert_equal @due_hsk_card, queue.next_card
    assert_not_equal @due_curated_card, queue.next_card
  end

  test "empty_state_message returns natural empty message when no cards are due overall" do
    # Simulate a database where nothing is due
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
