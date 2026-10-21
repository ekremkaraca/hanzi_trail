class StatsController < ApplicationController
  allow_unauthenticated_access

  def show
    @today_count = ReviewAttempt.today.count
    # Calendar week in the app's zone (today plus the
    # prior six days), so the counter rolls over at the
    # same local midnight as "Reviewed today" and the
    # streak instead of on a rolling 7x24h window.
    @week_count = ReviewAttempt
      .where(reviewed_at: 6.days.ago.beginning_of_day..Time.current.end_of_day)
      .count
    @total_count = ReviewAttempt.count
    # Keep the streak as a small aggregate so the view can render it directly.
    @streak = StreakCalculator.call
    @rating_breakdown = ReviewAttempt.group(:rating).count
    @recent_attempts = ReviewAttempt.recent.includes(:flashcard).limit(20)
    @difficult_cards = DifficultCards.call(limit: 10)
    @average_reviews_per_day = ReviewVelocity.call
  end
end
