module Flashcards
  module Index
    class PageComponent < ViewComponent::Base
      def initialize(flashcards:, params:)
        @flashcards = flashcards
        @params = params
      end

      private

      attr_reader :flashcards, :params

      def any_flashcards?
        flashcards.any?
      end

      def story_status
        params[:story_status]
      end
    end
  end
end
