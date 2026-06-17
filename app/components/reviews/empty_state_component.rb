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

    def new_session_path
      review_path(filter_params.merge(reset_session: "1"))
    end
  end
end
