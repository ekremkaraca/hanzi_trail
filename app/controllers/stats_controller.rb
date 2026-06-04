class StatsController < ApplicationController
  def show
    @today_count = ReviewAttempt.today.count
    @week_count = ReviewAttempt.where(reviewed_at: 7.days.ago..Time.current).count
    @total_count = ReviewAttempt.count
    @rating_breakdown = ReviewAttempt.group(:rating).count
    @recent_attempts = ReviewAttempt.recent.includes(:flashcard).limit(20)
  end
end
