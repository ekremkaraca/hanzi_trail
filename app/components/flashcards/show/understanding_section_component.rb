module Flashcards
  module Show
    class UnderstandingSectionComponent < ViewComponent::Base
      NOTES = [
        { attribute: :components,      title: "Components" },
        { attribute: :literal_meaning, title: "Literal meaning" },
        { attribute: :mnemonic,        title: "Memory hook" },
        { attribute: :usage_note,      title: "Usage note" }
      ].freeze

      def initialize(flashcard:)
        @flashcard = flashcard
      end

      def render?
        NOTES.any? { |note| flashcard.public_send(note[:attribute]).present? }
      end

      private

      attr_reader :flashcard
    end
  end
end
