module Stats
  class PageComponent < ViewComponent::Base
    def initialize(
      today_count:,
      week_count:,
      total_count:,
      average_reviews_per_day:,
      streak:,
      rating_breakdown:,
      recent_attempts:,
      difficult_cards:
    )
      @today_count = today_count
      @week_count = week_count
      @total_count = total_count
      @average_reviews_per_day = average_reviews_per_day
      @streak = streak
      @rating_breakdown = rating_breakdown
      @recent_attempts = recent_attempts
      @difficult_cards = difficult_cards
    end

    private

    attr_reader :today_count, :week_count, :total_count, :average_reviews_per_day,
                :streak, :rating_breakdown, :recent_attempts, :difficult_cards

    def stat_cards
      [
        { label: "Reviewed today",   value: today_count },
        { label: "Last 7 days",      value: week_count },
        { label: "Total reviews",    value: total_count },
        { label: "Avg / active day", value: average_reviews_per_day }
      ]
    end
  end
end
