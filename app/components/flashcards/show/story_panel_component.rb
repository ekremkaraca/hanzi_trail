module Flashcards
  module Show
    class StoryPanelComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      def render?
        flashcard.story.present?
      end

      private

      attr_reader :flashcard
    end
  end
end
