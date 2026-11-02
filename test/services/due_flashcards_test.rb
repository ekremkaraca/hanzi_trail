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

  test "caps never-reviewed cards at the daily budget, oldest-due first" do
    new_cards = Array.new(25) do |i|
      Flashcard.create!(
        character: "字#{i}",
        pinyin: "zì #{i}",
        meaning: "counter #{i}",
        next_review_at: i.minutes.ago
      )
    end

    admitted = DueFlashcards.call.to_a

    assert_equal DueFlashcards::NEW_CARDS_PER_DAY, admitted.size
    # due_for_review sorts oldest-first: the budget goes to the 20 cards
    # that have waited longest (created newest -> oldest, so take the tail).
    assert_equal new_cards.reverse.first(DueFlashcards::NEW_CARDS_PER_DAY), admitted
  end

  test "reviewed cards are never capped" do
    25.times do |i|
      Flashcard.create!(
        character: "复#{i}",
        pinyin: "fù #{i}",
        meaning: "reviewed #{i}",
        review_count: 1,
        next_review_at: 1.minute.ago
      )
    end

    assert_equal 25, DueFlashcards.call.count
  end

  test "new cards introduced today consume the budget" do
    introduced = Flashcard.create!(
      character: "今",
      pinyin: "jīn",
      meaning: "introduced today",
      review_count: 1,
      next_review_at: 1.minute.ago
    )
    ReviewAttempt.create!(flashcard: introduced, rating: "again",
                          reviewed_at: Time.current)

    20.times do |i|
      Flashcard.create!(
        character: "新#{i}",
        pinyin: "xīn #{i}",
        meaning: "new #{i}",
        next_review_at: 1.minute.ago
      )
    end

    admitted = DueFlashcards.call.to_a

    assert_includes admitted, introduced
    assert_equal 19, admitted.count { |card| card.review_count.zero? },
                 "one budget slot was spent on the card introduced today"
  end

  test "nil cap disables the governor" do
    25.times do |i|
      Flashcard.create!(
        character: "免#{i}",
        pinyin: "miǎn #{i}",
        meaning: "uncapped #{i}",
        next_review_at: 1.minute.ago
      )
    end

    assert_equal 25, DueFlashcards.call(new_cap: nil).count
  end
end
