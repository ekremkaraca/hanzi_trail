require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
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
    existing = flashcards(:one)

    duplicate = Flashcard.new(
      character: existing.character,
      pinyin: "wǎng",
      meaning: "network"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:character], "has already been taken"
  end

  test "due_for_review returns cards whose next_review_at is in the past" do
    due = Flashcard.create!(
      character: "中国",
      pinyin: "Zhōngguó",
      meaning: "China",
      next_review_at: 1.minute.ago
    )

    not_due = Flashcard.create!(
      character: "北京",
      pinyin: "Běijīng",
      meaning: "Beijing",
      next_review_at: 1.day.from_now
    )

    assert_includes Flashcard.due_for_review, due
    refute_includes Flashcard.due_for_review, not_due
  end

  test "schedule_next_review increments review count" do
    card = flashcards(:one)

    assert_difference -> { card.reload.review_count }, 1 do
      card.schedule_next_review!("good")
    end
  end

  test "schedule_next_review updates difficulty" do
    card = flashcards(:one)

    card.schedule_next_review!("hard")

    assert_equal "hard", card.reload.difficulty
  end

  test "schedule_next_review rejects invalid rating" do
    card = flashcards(:one)

    assert_raises(ArgumentError) do
      card.schedule_next_review!("perfect")
    end
  end
end
