module Reviews
  class AnswerSectionComponent < ViewComponent::Base
    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard

    def tab_list
      helpers.review_answer_tab_list(flashcard)
    end

    def tab_panels
      helpers.review_answer_tab_panels(flashcard)
    end
  end
end
