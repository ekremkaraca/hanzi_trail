module Flashcards
  module Show
    class CharacterNoteComponent < ViewComponent::Base
      def initialize(flashcard:, attribute:, title:)
        @flashcard = flashcard
        @attribute = attribute
        @title = title
      end

      def render?
        flashcard.public_send(attribute).present?
      end

      private

      attr_reader :flashcard, :attribute, :title

      def body
        flashcard.public_send(attribute)
      end
    end
  end
end
