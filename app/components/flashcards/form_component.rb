module Flashcards
  class FormComponent < ViewComponent::Base
    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard

    def has_errors?
      flashcard.errors.any?
    end

    def error_messages
      flashcard.errors.full_messages
    end
  end
end
