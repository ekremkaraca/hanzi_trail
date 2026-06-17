module Flashcards
  module Show
    class CharacterLinksComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      def render?
        flashcard.flashcard_characters.any?
      end

      private

      attr_reader :flashcard
    end
  end
end
