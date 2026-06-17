module Flashcards
  module Show
    class DetailGridComponent < ViewComponent::Base
      def initialize(flashcard:)
        @flashcard = flashcard
      end

      private

      attr_reader :flashcard

      # DRY: shared "Overdue by X" / "Due in Y" formatting (moved from FlashcardsHelper)
      def next_review_text
        time = flashcard.next_review_at

        if time.past?
          "Overdue by #{helpers.distance_of_time_in_words(time, Time.current)}"
        else
          "Due in #{helpers.distance_of_time_in_words(Time.current, time)}"
        end
      end
    end
  end
end
