module Flashcards
  module Index
    class FilterBarComponent < ViewComponent::Base
      def initialize(params:)
        @params = params
      end

      private

      attr_reader :params

      def query
        params[:query]
      end

      def source
        params[:source]
      end

      def hsk_level
        params[:hsk_level]
      end

      def category
        params[:category]
      end

      def story_status
        params[:story_status]
      end
    end
  end
end
