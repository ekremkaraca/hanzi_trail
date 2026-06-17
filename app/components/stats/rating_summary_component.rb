module Stats
  class RatingSummaryComponent < ViewComponent::Base
    def initialize(rating_breakdown:)
      @rating_breakdown = rating_breakdown
    end

    private

    attr_reader :rating_breakdown

    # DRY: shared REVIEW_RATINGS constant from StatsHelper
    def ratings
      StatsHelper::REVIEW_RATINGS
    end

    def count_for(rating)
      rating_breakdown[rating] || 0
    end
  end
end
