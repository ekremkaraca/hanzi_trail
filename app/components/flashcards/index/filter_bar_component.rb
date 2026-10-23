module Flashcards
  module Index
    class FilterBarComponent < ViewComponent::Base
      def initialize(params:)
        @params = params
      end

      private

      attr_reader :params

      # Values come back out of the query string into form fields, so they
      # go through the same scalar guard the controllers use for scopes:
      # ?query[]=a is an Array, and its to_s would render a literal
      # &[quot;a&quot;] back into the input. Non-String shapes read as absent.
      def query
        QueryParam.scalar(params[:query])
      end

      def source
        QueryParam.scalar(params[:source])
      end

      def hsk_level
        QueryParam.scalar(params[:hsk_level])
      end

      def category
        QueryParam.scalar(params[:category])
      end

      def story_status
        QueryParam.scalar(params[:story_status])
      end
    end
  end
end
