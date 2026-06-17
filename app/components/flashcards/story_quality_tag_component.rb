module Flashcards
  class StoryQualityTagComponent < ViewComponent::Base
    def initialize(flashcard:)
      @flashcard = flashcard
    end

    def render?
      flashcard.short_story?
    end

    private

    attr_reader :flashcard
  end
end
