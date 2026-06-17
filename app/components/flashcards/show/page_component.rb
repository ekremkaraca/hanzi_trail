module Flashcards
  module Show
    class PageComponent < ViewComponent::Base
      def initialize(flashcard:, session:)
        @flashcard = flashcard
        @session = session
      end

      private

      attr_reader :flashcard, :session

      # DRY: shared "X ago" / "Never" formatting (moved from FlashcardsHelper)
      def last_reviewed_text
        return "Never" if flashcard.last_reviewed_at.blank?

        "#{helpers.time_ago_in_words(flashcard.last_reviewed_at)} ago"
      end

      def active_review_path
        session[:review_return_to]
      end
    end
  end
end
