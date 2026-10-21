module Flashcards
  module Index
    class PageComponent < ViewComponent::Base
      def initialize(flashcards:, params:, current_page:, has_more:)
        @flashcards = flashcards
        @params = params
        @current_page = current_page
        @has_more = has_more
      end

      private

      attr_reader :flashcards, :params, :current_page, :has_more

      def any_flashcards?
        flashcards.any?
      end

      def story_status
        params[:story_status]
      end

      def show_previous?
        current_page > 1
      end

      # Keep the active filters on the page links so paging
      # does not reset them.
      def page_params(page)
        params
          .permit(:source, :hsk_level, :category, :story_status, :query)
          .merge(page: page)
      end
    end
  end
end
