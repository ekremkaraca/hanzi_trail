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
          "symbol--phrase"
        elsif length >= 3
          "symbol--long"
        end
      end
    end
  end
end
