module Stats
  class RatingBreakdownComponent < ViewComponent::Base
    def initialize(rating_breakdown:)
      @rating_breakdown = rating_breakdown
    end

    private

    attr_reader :rating_breakdown

    def ratings
      StatsHelper::REVIEW_RATINGS
    end

    def count_for(rating)
      rating_breakdown.fetch(rating, 0)
    end

    def total_ratings
      rating_breakdown.values.sum
    end

    def progress_max
      total_ratings.positive? ? total_ratings : 1
    end

    def progress_class(rating)
      helpers.rating_progress_class(rating)
    end
  end
end
