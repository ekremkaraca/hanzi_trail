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
end
