module Reviews
  class PromptComponent < ViewComponent::Base
    def initialize(flashcard:, show_pinyin:)
      @flashcard = flashcard
      @show_pinyin = show_pinyin
    end

    private

    attr_reader :flashcard, :show_pinyin
  end
end
