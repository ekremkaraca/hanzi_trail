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

  test "rejects overly long story" do
    card = flashcards(:network)
    card.story = "x" * 2_001

    assert_not card.valid?
    assert_includes card.errors[:story], "is too long (maximum is 2000 characters)"
  end

  test "schedule_next_review with again sets 1 minute interval" do
    freeze_time do
      @default_card.update!(next_review_at: 1.minute.ago)
      @default_card.schedule_next_review!("again")
      assert_in_delta 1.minute.from_now, @default_card.reload.next_review_at, 1.second
    end
  end

  test "schedule_next_review with hard sets 1 day interval" do
    freeze_time do
      @default_card.update!(next_review_at: 1.minute.ago)
      @default_card.schedule_next_review!("hard")
      assert_in_delta 1.day.from_now, @default_card.reload.next_review_at, 1.second
    end
  end

  test "schedule_next_review with good sets 3 day interval" do
    freeze_time do
      @default_card.update!(next_review_at: 1.minute.ago)
      @default_card.schedule_next_review!("good")
      assert_in_delta 3.days.from_now, @default_card.reload.next_review_at, 1.second
    end
  end

  test "schedule_next_review with easy sets 7 day interval" do
    freeze_time do
      @default_card.update!(next_review_at: 1.minute.ago)
      @default_card.schedule_next_review!("easy")
      assert_in_delta 7.days.from_now, @default_card.reload.next_review_at, 1.second
    end
  end

  test "by_source scope filters by source" do
    curated = flashcards(:network)
    hsk = flashcards(:hsk_one)

    assert_includes Flashcard.by_source("curated"), curated
    refute_includes Flashcard.by_source("curated"), hsk
  end

  test "by_source scope returns all when blank" do
    assert_equal Flashcard.count, Flashcard.by_source("").count
  end

  test "by_hsk_level scope filters by hsk level" do
    hsk_one = flashcards(:hsk_one)
    curated = flashcards(:network)

    assert_includes Flashcard.by_hsk_level("old-1"), hsk_one
    refute_includes Flashcard.by_hsk_level("old-1"), curated
  end

  test "by_hsk_level scope returns all when blank" do
    assert_equal Flashcard.count, Flashcard.by_hsk_level("").count
  end

  test "by_category scope filters by category" do
    technical = flashcards(:network)
    education = flashcards(:overdue_review)

    assert_includes Flashcard.by_category("technical"), technical
    refute_includes Flashcard.by_category("technical"), education
  end

  test "by_category scope returns all when blank" do
    assert_equal Flashcard.count, Flashcard.by_category("").count
  end

  test "by_story_status scope filters by story status" do
    @default_card.update!(story_status: "curated")
    hsk = flashcards(:hsk_one)
    hsk.update!(story_status: "missing")

    assert_includes Flashcard.by_story_status("curated"), @default_card
    refute_includes Flashcard.by_story_status("curated"), hsk
  end

  test "by_story_status scope returns all when blank" do
    assert_equal Flashcard.count, Flashcard.by_story_status("").count
  end

  test "missing_story scope returns cards with missing story" do
    @default_card.update!(story_status: "curated")
    hsk = flashcards(:hsk_one)
    hsk.update!(story_status: "missing")

    assert_includes Flashcard.missing_story, hsk
    refute_includes Flashcard.missing_story, @default_card
  end

  test "draft_story scope returns cards with draft story" do
    @default_card.update!(story_status: "draft")
    hsk = flashcards(:hsk_one)
    hsk.update!(story_status: "missing")

    assert_includes Flashcard.draft_story, @default_card
    refute_includes Flashcard.draft_story, hsk
  end

  test "curated_story scope returns cards with curated story" do
    @default_card.update!(story_status: "curated")
    hsk = flashcards(:hsk_one)
    hsk.update!(story_status: "missing")

    assert_includes Flashcard.curated_story, @default_card
    refute_includes Flashcard.curated_story, hsk
  end

  test "short_story scope returns cards with short non-blank stories" do
    @default_card.update!(story: "Short story.")
    long = flashcards(:algorithm)
    long.update!(story: "x" * Flashcard::SHORT_STORY_LENGTH)

    assert_includes Flashcard.short_story, @default_card
    refute_includes Flashcard.short_story, long
  end

  test "short_story scope excludes blank and nil stories" do
    flashcards(:hsk_one).update!(story: "")
    flashcards(:hsk_two).update!(story: nil)
    flashcards(:network).update!(story: "x" * Flashcard::SHORT_STORY_LENGTH)
    flashcards(:algorithm).update!(story: "x" * Flashcard::SHORT_STORY_LENGTH)
    flashcards(:future_review).update!(story: "x" * Flashcard::SHORT_STORY_LENGTH)
    flashcards(:overdue_review).update!(story: "x" * Flashcard::SHORT_STORY_LENGTH)

    assert_empty Flashcard.short_story
  end

  test "rejects invalid source" do
    card = flashcards(:network)
    card.source = "invalid"

    assert_not card.valid?
    assert_includes card.errors[:source], "is not included in the list"
  end

  test "rejects invalid difficulty" do
    card = flashcards(:network)
    card.difficulty = "impossible"

    assert_not card.valid?
    assert_includes card.errors[:difficulty], "is not included in the list"
  end

  test "rejects negative review count" do
    card = flashcards(:network)
    card.review_count = -1

    assert_not card.valid?
    assert_includes card.errors[:review_count], "must be greater than or equal to 0"
  end

  test "sync_story_status does not override existing status when story unchanged" do
    card = flashcards(:network)
    existing_story = card.story
    card.assign_attributes(story: existing_story, story_status: "draft")

    card.send(:sync_story_status)

    assert_equal "draft", card.story_status
  end

  test "rejects overly long components" do
    card = flashcards(:network)
    card.components = "x" * 1_001

    assert_not card.valid?
    assert_includes card.errors[:components], "is too long (maximum is 1000 characters)"
  end

  test "rejects overly long literal meaning" do
    card = flashcards(:network)
    card.literal_meaning = "x" * 501

    assert_not card.valid?
    assert_includes card.errors[:literal_meaning], "is too long (maximum is 500 characters)"
  end

  test "rejects overly long mnemonic" do
    card = flashcards(:network)
    card.mnemonic = "x" * 1_001

    assert_not card.valid?
    assert_includes card.errors[:mnemonic], "is too long (maximum is 1000 characters)"
  end

  test "rejects overly long usage note" do
    card = flashcards(:network)
    card.usage_note = "x" * 1_001

    assert_not card.valid?
    assert_includes card.errors[:usage_note], "is too long (maximum is 1000 characters)"
  end

  test "rejects overly long meaning" do
    card = flashcards(:network)
    card.meaning = "x" * 501

    assert_not card.valid?
    assert_includes card.errors[:meaning], "is too long (maximum is 500 characters)"
  end

  test "sets story status to missing when story is blank on create" do
    card = Flashcard.create!(
      character: "明",
      pinyin: "míng",
      meaning: "bright",
      story: ""
    )

    assert_equal "missing", card.reload.story_status
  end

  test "sets story status to curated when story is present on create" do
    card = Flashcard.create!(
      character: "術",
      pinyin: "xué",
      meaning: "study",
      story: "A learning-related character."
    )

    assert_equal "curated", card.reload.story_status
  end

  test "preserves explicit draft story status" do
    card = flashcards(:network)

    card.update!(
      story: "Needs editorial review.",
      story_status: "draft"
    )

    assert_equal "draft", card.reload.story_status
  end

  test "updates missing story status when story is added" do
    card = flashcards(:hsk_one)
    card.update!(story: "")

    assert_equal "missing", card.reload.story_status

    card.update!(story: "Now this card has a story.")

    assert_equal "curated", card.reload.story_status
  end

  test "character linker creates entries for multi character word" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    CharacterLinker.call(card)

    assert_equal 2, card.flashcard_characters.count
  end

  test "with_story_filter short returns short stories" do
    results = Flashcard.with_story_filter("short")

    assert results.all?(&:short_story?)
  end

  test "with_story_filter curated returns curated cards" do
    results = Flashcard.with_story_filter("curated")

    assert results.all? { |card| card.story_status == "curated" }
  end
end
