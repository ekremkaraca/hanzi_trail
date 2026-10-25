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

  test "the card and its count come from one bounded read" do
    %i[algorithm network hsk_one].each do |tag|
      flashcards(tag).update!(next_review_at: 1.hour.ago)
    end

    queue = Review::Queue.new(filters: {}, session: {})

    reads = 0
    counter = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      reads += 1 if payload[:sql].include?(%q(FROM "flashcards"))
    end

    assert_equal 3, queue.remaining_count
    assert queue.next_card
    # next_card and remaining_count share one materialized page, so the
    # second call must not ask the database again. Two reads now: the
    # new-card budget pluck (DueFlashcards governor) + the page itself.
    assert_equal 2, reads
  ensure
    ActiveSupport::Notifications.unsubscribe(counter)
  end

  test "the due-card read is bounded by a LIMIT" do
    # The cap bounds the rows a page view can load; the LIMIT is asserted
    # in the issued SQL rather than simulated with a tiny cap, since the
    # fixtures can never reach 500 cards.
    flashcards(:algorithm).update!(next_review_at: 1.hour.ago)
    queue = Review::Queue.new(filters: {}, session: {})

    sqls = []
    counter = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      sqls << [ payload[:sql], payload[:binds]&.map { |b| b.value rescue b } ] if payload[:sql].include?(%q(FROM "flashcards"))
    end

    assert_equal flashcards(:algorithm), queue.next_card
  ensure
    ActiveSupport::Notifications.unsubscribe(counter)
    # Budget pluck + bounded page read (see DueFlashcards new-card governor).
    assert_equal 2, sqls.size
    # The adapter parameterizes the LIMIT (LIMIT $2), so the cap is read
    # back from the binds rather than the SQL text. The page read is the
    # one whose binds carry DUE_READ_CAP (the pluck carries the smaller
    # new-card budget).
    sql, binds = sqls.find { |_s, b| b&.include?(Review::Queue::DUE_READ_CAP) }
    assert sql, "no flashcards read carried LIMIT #{Review::Queue::DUE_READ_CAP}: #{sqls.inspect}"
    assert_includes sql, "LIMIT $"
    assert_not_includes sql, "COUNT(*)"
  end
end
