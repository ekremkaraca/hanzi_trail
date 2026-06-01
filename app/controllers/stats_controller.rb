class StatsController < ApplicationController
  def show
    @today_count = ReviewAttempt.today.count

    @rating_breakdown = ReviewAttempt
      .group(:rating)
      .count

    @recent_attempts = ReviewAttempt
      .recent
      .limit(20)
  end
end
