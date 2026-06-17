module Flashcards
  class RowComponent < ViewComponent::Base
    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard
  end
end
