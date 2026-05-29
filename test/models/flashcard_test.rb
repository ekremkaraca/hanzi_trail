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

  test "schedule_next_review raises CardNotDueError when next_review_at is in the future" do
    future_card = flashcards(:future_review)

    assert_raises(Flashcard::CardNotDueError) do
      future_card.schedule_next_review!("good")
    end
  end

  test "schedule_next_review does not change card when not due" do
    future_card = flashcards(:future_review)
    original_review_at = future_card.next_review_at
    original_review_count = future_card.review_count

    begin
      future_card.schedule_next_review!("good")
    rescue Flashcard::CardNotDueError
      # expected
    end

    assert_equal original_review_at, future_card.reload.next_review_at
    assert_equal original_review_count, future_card.review_count
  end

  test "defaults story status to missing when story is blank" do
    flashcard = Flashcard.new(
      character: "新",
      pinyin: "xīn",
      meaning: "new",
      category: "general",
      difficulty: "new",
      review_count: 0,
      next_review_at: Time.current
    )

    assert flashcard.valid?
    assert_equal "missing", flashcard.story_status
  end

  test "defaults story status to curated when story is present" do
    flashcard = Flashcard.new(
      character: "文",
      pinyin: "wén",
      meaning: "text; writing",
      story: "A written mark becomes meaning.",
      category: "general",
      difficulty: "new",
      review_count: 0,
      next_review_at: Time.current
    )

    assert flashcard.valid?
    assert_equal "curated", flashcard.story_status
  end

  test "allows draft story status" do
    flashcard = flashcards(:network)

    flashcard.story_status = "draft"

    assert flashcard.valid?
  end

  test "rejects invalid story status" do
    flashcard = flashcards(:network)

    flashcard.story_status = "published"

    assert_not flashcard.valid?
    assert_includes flashcard.errors[:story_status], "is not included in the list"
  end

  test "search returns all flashcards when query is blank" do
    assert_equal Flashcard.count, Flashcard.search("").count
  end

  test "search finds flashcard by character" do
    results = Flashcard.search("网")

    assert_includes results, @default_card
  end

  test "search finds flashcard by pinyin" do
    results = Flashcard.search("wǎng")

    assert_includes results, @default_card
  end

  test "search finds flashcard by meaning" do
    results = Flashcard.search("network")

    assert_includes results, @default_card
  end

  test "search finds flashcard by category" do
    results = Flashcard.search("technical")

    assert_includes results, @default_card
  end

  test "search safely handles wildcard characters" do
    result = Flashcard.search("%")

    assert_empty result
  end

  test "story_missing? returns true for missing story status" do
    flashcard = flashcards(:hsk_one)
    flashcard.story_status = "missing"

    assert flashcard.story_missing?
    assert_not flashcard.story_curated?
    assert_not flashcard.story_draft?
  end

  test "story_draft? returns true for draft story status" do
    flashcard = flashcards(:network)
    flashcard.story_status = "draft"

    assert flashcard.story_draft?
    assert_not flashcard.story_curated?
    assert_not flashcard.story_missing?
  end

  test "story_curated? returns true for curated story status" do
    flashcard = flashcards(:network)
    flashcard.story_status = "curated"

    assert flashcard.story_curated?
    assert_not flashcard.story_draft?
    assert_not flashcard.story_missing?
  end

  test "short_story returns true for short non-blank story" do
    flashcard = flashcards(:network)
    flashcard.story = "A network of connections."

    assert flashcard.short_story?
  end

  test "short_story returns false for blank story" do
    flashcard = flashcards(:hsk_one)
    flashcard.story = nil

    assert_not flashcard.short_story?
  end

  test "schedule_next_review creates review attempt" do
    card = flashcards(:network)
    card.update!(next_review_at: 1.minute.ago)

    assert_difference("ReviewAttempt.count", 1) do
      card.schedule_next_review!("good")
    end

    attempt = ReviewAttempt.last

    assert_equal card, attempt.flashcard
    assert_equal "good", attempt.rating
  end
end
