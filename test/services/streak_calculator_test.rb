require "test_helper"

class StreakCalculatorTest < ActiveSupport::TestCase
  test "returns zero when there are no attempts for today" do
    # Freeze the date so the current-day lookup is stable.
    freeze_time do
      # Clear fixture attempts so this test measures the empty state directly.
      ReviewAttempt.delete_all

      assert_equal 0, StreakCalculator.call
    end
  end

  test "counts a single current-day streak" do
    # Keep all review timestamps on the same frozen day.
    freeze_time do
      # Remove seeded attempts so only this review contributes to the streak.
      ReviewAttempt.delete_all

      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: Time.current
      )

      assert_equal 1, StreakCalculator.call
    end
  end

  test "counts consecutive days from today backwards" do
    # Spread the attempts across adjacent days to exercise the streak walk.
    freeze_time do
      # Start from a clean review table so the streak is entirely self-contained.
      ReviewAttempt.delete_all

      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: Time.current
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: 1.day.ago
      )
      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: 2.days.ago
      )

      assert_equal 3, StreakCalculator.call
    end
  end

  test "counts attempts from the local day even when their UTC date is earlier" do
    # 00:30 Istanbul lands on the previous calendar day in UTC (21:30).
    travel_to Time.zone.local(2026, 10, 11, 0, 30, 0) do
      ReviewAttempt.delete_all

      ReviewAttempt.create!(
        flashcard: flashcards(:network),
        rating: "good",
        reviewed_at: Time.current
      )

      assert_equal 1, StreakCalculator.call
    end
  end

  test "attempts outside the window cannot extend the streak past it" do
    # A broken run (day -368 with a gap, then today) must read as 1, and
    # a run covering every pluckable day must stop at the window's edge
    # rather than scanning all history.
    freeze_time do
      ReviewAttempt.delete_all
      card = flashcards(:network)
      window = StreakCalculator::WINDOW_DAYS

      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current)
      # Day -368: two days outside the window (whose boundary is
      # beginning_of_day on -366), separated by a gap on -367, so it can
      # never join the walk even before the bound applies.
      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: (window + 2).days.ago)

      assert_equal 1, StreakCalculator.call

      # Continuous coverage of every pluckable local day (-366 through
      # today = WINDOW_DAYS + 1 calendar days). Day -367 falls outside
      # the window and must not count, so the streak stops at the edge
      # instead of reaching into unbounded history.
      ReviewAttempt.delete_all
      (0..window).each do |offset|
        # Day -window (the first day the window plucks) through today.
        ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: offset.days.ago.end_of_day)
      end
      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: (window + 1).days.ago)

      assert_equal window + 1, StreakCalculator.call
    end
  end
end
