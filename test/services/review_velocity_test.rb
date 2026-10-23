require "test_helper"

class ReviewVelocityTest < ActiveSupport::TestCase
  test "returns zero when there are no review attempts" do
    ReviewAttempt.delete_all

    assert_equal 0, ReviewVelocity.call
  end

  test "calculates average reviews per active day" do
    ReviewAttempt.delete_all

    card = flashcards(:network)

    2.times do
      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current)
    end

    ReviewAttempt.create!(flashcard: card, rating: "hard", reviewed_at: 1.day.ago)

    assert_equal 1.5, ReviewVelocity.call
  end

  test "buckets attempts by local day when the UTC date differs" do
    # Two attempts at 00:30 Istanbul share one local day but sit on
    # different UTC days; the average must be over one active day.
    travel_to Time.zone.local(2026, 10, 11, 0, 30, 0) do
      ReviewAttempt.delete_all
      card = flashcards(:network)

      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current)
      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current + 3.hours)

      assert_equal 2.0, ReviewVelocity.call
    end
  end

  test "attempts outside the window are excluded from both sides of the ratio" do
    # An old dense day must not inflate the numerator or the active-day
    # denominator: the average stays the one computed inside the window.
    freeze_time do
      ReviewAttempt.delete_all
      card = flashcards(:network)

      2.times { ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current) }
      # Outside the 366-day window: without the bound this day would add
      # one to dates.size and two to the total, changing 2.0 to 1.6.
      2.times { ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: (StreakCalculator::WINDOW_DAYS + 1).days.ago) }

      assert_equal 2.0, ReviewVelocity.call
    end
  end
end
