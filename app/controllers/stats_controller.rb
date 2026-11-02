class StatsController < ApplicationController
  allow_unauthenticated_access

  # The dashboard's seven review_attempts aggregates are day-granularity
  # numbers (two bounded day-bucketing plucks, a grouped rating count,
  # and three plain counts) rendered together on one page. They are now
  # served as a single short-TTL bundle: the common "open stats, browse
  # around, come back" path pays one recomputation for every visitor in
  # the window instead of nine queries each.
  #
  # One shared key means every visitor reads the same bundle, and a new
  # review can show up in the aggregates up to AGGREGATES_TTL late. No
  # write-side invalidation: these counters have no correctness role (no
  # money, no quota), and a reviewer landing here right after a review
  # still sees their own attempt in @recent_attempts, which stays live.
  # Bump the TTL only with that staleness trade written down.
  AGGREGATES_CACHE_KEY = "stats/aggregates/v1".freeze
  AGGREGATES_TTL = 1.minute

  def show
    stats = Rails.cache.fetch(AGGREGATES_CACHE_KEY, expires_in: AGGREGATES_TTL) do
      {
        today_count: ReviewAttempt.today.count,
        # Calendar week in the app's zone (today plus the
        # prior six days), so the counter rolls over at the
        # same local midnight as "Reviewed today" and the
        # streak instead of on a rolling 7x24h window.
        week_count: ReviewAttempt
                    .where(reviewed_at: 6.days.ago.beginning_of_day..Time.current.end_of_day)
                    .count,
        total_count: ReviewAttempt.count,
        # Keep the streak as a small aggregate so the view can render it directly.
        streak: StreakCalculator.call,
        rating_breakdown: ReviewAttempt.group(:rating).count,
        average_reviews_per_day: ReviewVelocity.call,
        # Cached as loaded records: the bundle is re-read whole, so the
        # view never re-queries the join.
        difficult_cards: DifficultCards.call(limit: 10).to_a
      }
    end

    @today_count = stats[:today_count]
    @week_count = stats[:week_count]
    @total_count = stats[:total_count]
    @streak = stats[:streak]
    @rating_breakdown = stats[:rating_breakdown]
    @average_reviews_per_day = stats[:average_reviews_per_day]
    @difficult_cards = stats[:difficult_cards]
    # The recent-activity feed stays outside the bundle: it is the one
    # stat whose point is "what just happened".
    @recent_attempts = ReviewAttempt.recent.includes(:flashcard).limit(20)
  end
end
