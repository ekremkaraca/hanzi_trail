module Reviews
  class ActionsComponent < ViewComponent::Base
    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard

    def rating_buttons
      helpers.review_buttons_for(flashcard)
    end

    def shortcut_keys
      helpers.review_shortcut_keys
    end
  end
end
