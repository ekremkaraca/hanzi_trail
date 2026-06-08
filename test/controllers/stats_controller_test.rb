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
    assert_select "#most-difficult .stats-list-item", count: 3
    assert_select "#most-difficult .stats-list-item", text: /#{Regexp.escape(flashcards(:network).character)}/
    assert_select "#recently-reviewed .stats-list-item", text: /#{Regexp.escape(flashcards(:algorithm).character)}/
    refute_includes response.body, "Again: 124"
    refute_includes response.body, "Hard: 88"
    refute_includes response.body, "Good: 510"
    refute_includes response.body, "Easy: 293"
  end
end
