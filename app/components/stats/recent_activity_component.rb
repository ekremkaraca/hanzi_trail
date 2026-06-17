module Stats
  class RecentActivityComponent < ViewComponent::Base
    def initialize(recent_attempts:)
      @recent_attempts = recent_attempts
    end

    private

    attr_reader :recent_attempts

    def any_attempts?
      recent_attempts.any?
    end

    def flashcard_path(attempt)
      helpers.flashcard_path(attempt.flashcard)
    end

    def reviewed_ago(attempt)
      "#{helpers.time_ago_in_words(attempt.reviewed_at)} ago"
    end
  end
end
