module Reviews
  class EmptyStateComponent < ViewComponent::Base
    def initialize(reviewed_count:, filter_params:, title: nil)
      @reviewed_count = reviewed_count
      @filter_params = filter_params
      @title = title
    end

    private

    attr_reader :reviewed_count, :filter_params, :title

    def has_reviewed_cards?
      reviewed_count.to_i.positive?
    end

    # "Start new session" restarts the counter via PATCH review/reset.
    def new_session_path
      review_reset_path(filter_params)
    end
  end
end
