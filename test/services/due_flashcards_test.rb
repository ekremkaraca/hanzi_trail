require "test_helper"

class DueFlashcardsTest < ActiveSupport::TestCase
  setup do
    Flashcard.update_all(next_review_at: 1.day.from_now)
  end

  test "returns due cards ordered by next review time" do
    older = flashcards(:network)
    newer = flashcards(:algorithm)

    older.update!(next_review_at: 2.days.ago)
    newer.update!(next_review_at: 1.hour.ago)

    assert_equal [ older, newer ], DueFlashcards.call.to_a
  end
end
