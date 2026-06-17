module Stats
  class RecentReviewsComponent < ViewComponent::Base
    def initialize(recent_attempts:)
      @recent_attempts = recent_attempts
    end

    private

    attr_reader :recent_attempts

    def display_attempts
      recent_attempts.first(3)
    end

    def any_attempts?
      recent_attempts.any?
    end

    def reviewed_ago(attempt)
      "#{helpers.time_ago_in_words(attempt.reviewed_at)} ago"
    end
  end
end
