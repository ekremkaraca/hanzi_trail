module Reviews
  module TabPanels
    class StoryTabComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      private

      attr_reader :flashcard
    end
  end
end
