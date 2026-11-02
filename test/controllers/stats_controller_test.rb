require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "shows review stats" do
    freeze_time do
      # Pin the calendar days so the streak card can be asserted deterministically.
      ReviewAttempt.delete_all

      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "again",
        reviewed_at: Time.current
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "hard",
        reviewed_at: 1.day.ago
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:algorithm),
        rating: "good",
        reviewed_at: 2.days.ago
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:algorithm),
        rating: "hard",
        reviewed_at: 90.minutes.ago
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:hsk_one),
        rating: "again",
        reviewed_at: 30.minutes.ago
      )

      get stats_url
    end

    assert_response :success
    assert_select "#current-streak span", text: "Current streak"
    assert_select "#current-streak strong", text: "3"
    assert_select "#rating-summary .stats-card-label", text: "Again"
    assert_select "#rating-summary .stats-card-value", text: "2"
    assert_select "#most-difficult .difficult-card-item", count: 3
    assert_select "#most-difficult .difficult-card-item", text: /#{Regexp.escape(flashcards(:network).character)}/
    assert_includes response.body, "2 hard reviews"
    assert_select "#recently-reviewed .stats-list-item", text: /#{Regexp.escape(flashcards(:algorithm).character)}/
  end

  test "shows recent activity" do
    card = flashcards(:network)

    ReviewAttempt.create!(
      flashcard: card,
      rating: "good",
      reviewed_at: Time.current
    )

    get stats_path

    assert_response :success
    assert_select ".activity-item", minimum: 1
  end

  test "week count buckets by calendar day, not a rolling 7x24h window" do
    freeze_time do
      ReviewAttempt.delete_all

      # An hour into this week's first calendar day counts...
      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: 6.days.ago.beginning_of_day + 1.hour
      )
      # ...but the hour before it does not, even though a
      # rolling 7x24h window would still include it.
      ReviewAttempt.create!(
        flashcard: flashcards(:algorithm),
        rating: "good",
        reviewed_at: 6.days.ago.beginning_of_day - 1.hour
      )

      get stats_url
    end

    assert_response :success
    assert_match(%r{Last 7 days.{0,200}?<strong[^>]*>1</strong>}m, response.body)
  end

  test "the aggregate bundle is computed once per TTL, the feed is not" do
    # The suite's NullStore keeps nothing, so the cache path has to be
    # exercised with a real store - swapped here and restored in ensure,
    # the way the rate-limit tests swap the store's increment.
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # First request: the seven aggregates (today, week, total, streak
    # pluck, rating breakdown, velocity dates, velocity total) plus the
    # feed's own reads - the limit query, its preload, and the two
    # any? EXISTS probes the activity components make over it.
    first = count_attempt_queries { get stats_path }
    assert_response :success
    assert_equal 11, first

    # Second request inside the TTL: the bundle is reused, so only the
    # fresh feed remains - 4 reads, none of them an aggregate.
    second = count_attempt_queries { get stats_path }
    assert_response :success
    assert_equal 4, second
    # The seven aggregate reads are exactly the saving; if the bundle were
    # ignored this would equal the first count again.
    assert_operator second, :<, first
  ensure
    Rails.cache = previous_cache
  end

  private

  def count_attempt_queries
    count = 0
    counter = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count += 1 if payload[:sql].include?('FROM "review_attempts"')
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(counter)
  end
end
