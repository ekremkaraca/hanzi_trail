require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
  setup do
    @default_card = flashcards(:network)
    @future_review = flashcards(:future_review)
    @overdue_review = flashcards(:overdue_review)
  end
  test "valid with required fields" do
    card = Flashcard.new(
    character: "新",
    pinyin: "xīn",
    meaning: "new"
  )

    assert card.valid?, card.errors.full_messages.to_sentence
    assert_equal "new", card.difficulty
    assert_equal 0, card.review_count
    assert card.next_review_at.present?
  end

  test "character must be unique" do
    duplicate = Flashcard.new(
      character: @default_card.character,
      pinyin: "wǎng",
      meaning: "network"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:character], "has already been taken"
  end

  test "due_for_review returns cards whose next_review_at is in the past" do
    overdue_review = flashcards(:overdue_review)
    future_review = flashcards(:future_review)

    assert_includes Flashcard.due_for_review, overdue_review
    refute_includes Flashcard.due_for_review, future_review
  end

  test "schedule_next_review increments review count" do
    assert_difference -> { @default_card.reload.review_count }, 1 do
      @default_card.schedule_next_review!("good")
    end
  end

  test "schedule_next_review updates difficulty" do
    @default_card.schedule_next_review!("hard")

    assert_equal "hard", @default_card.reload.difficulty
  end

  test "schedule_next_review rejects invalid rating" do
    @default_card = flashcards(:network)

    assert_raises(ArgumentError) do
      @default_card.schedule_next_review!("perfect")
    end
  end
end
