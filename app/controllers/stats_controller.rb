class StatsController < ApplicationController
  def show
    @today_count = ReviewAttempt.today.count
    @week_count = ReviewAttempt.where(reviewed_at: 7.days.ago..Time.current).count
    @total_count = ReviewAttempt.count
    # Keep the streak as a small aggregate so the view can render it directly.
    @streak = StreakCalculator.call
    @rating_breakdown = ReviewAttempt.group(:rating).count
    @recent_attempts = ReviewAttempt.recent.includes(:flashcard).limit(20)
    @most_difficult_flashcards = Flashcard
      .left_joins(:review_attempts)
      .select(<<~SQL.squish)
        flashcards.*,
        COALESCE(SUM(CASE WHEN review_attempts.rating IN ('again', 'hard') THEN 1 ELSE 0 END), 0) AS difficult_review_count
      SQL
      .group("flashcards.id")
      .having("SUM(CASE WHEN review_attempts.rating IN ('again', 'hard') THEN 1 ELSE 0 END) > 0")
      .order(Arel.sql("difficult_review_count DESC"), character: :asc)
      .limit(3)
  end
end
