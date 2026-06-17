module Reviews
  class PageComponent < ViewComponent::Base
    def initialize(
      flashcard:,
      remaining_due_count:,
      empty_state_title:,
      reviewed_count:,
      filter_params:,
      total_review_count:,
      reviewed_today_count:,
      show_pinyin:
    )
      @flashcard = flashcard
      @remaining_due_count = remaining_due_count
      @empty_state_title = empty_state_title
      @reviewed_count = reviewed_count
      @filter_params = filter_params
      @total_review_count = total_review_count
      @reviewed_today_count = reviewed_today_count
      @show_pinyin = show_pinyin
    end

    private

    attr_reader :flashcard, :remaining_due_count, :empty_state_title, :reviewed_count,
                :filter_params, :total_review_count, :reviewed_today_count, :show_pinyin
  end
end
