module Reviews
  class ProgressComponent < ViewComponent::Base
    def initialize(reviewed_count:, total_review_count:, reviewed_today_count:, remaining_due_count:)
      @reviewed_count = reviewed_count
      @total_review_count = total_review_count
      @reviewed_today_count = reviewed_today_count
      @remaining_due_count = remaining_due_count
    end

    private

    attr_reader :reviewed_count, :total_review_count, :reviewed_today_count, :remaining_due_count

    def progress
      helpers.review_progress_percentage(reviewed_count, total_review_count)
    end
  end
end
