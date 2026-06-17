module Flashcards
  module Show
    class HeroComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      private

      attr_reader :flashcard

      # DRY: shared character-size class logic moved out of FlashcardsHelper
      def character_size_class
        length = flashcard.character.length

        if length >= 4
          "is-phrase-character"
        elsif length >= 3
          "is-long-character"
        end
      end
    end
  end
end
