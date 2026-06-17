module Reviews
  module TabPanels
    class BreakdownTabComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      private

      attr_reader :flashcard
    end
  end
end
