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

      # Options come from the data, not a hardcoded list: importing a new
      # band (or a future HSK level) needs no template change. Distinct
      # values only, so empty levels never appear.
      def hsk_level_options
        @hsk_level_options ||= [
          [ "All", "" ],
          *Flashcard.where.not(hsk_level: nil)
                   .distinct.order(:hsk_level)
                   .pluck(:hsk_level)
                   .map { |level| [ hsk_level_label(level), level ] }
        ]
      end

      # "new-3" -> "HSK 3" (the 3.0 scheme is the default learners see);
      # "old-3" -> "HSK 2.0 (3)" while legacy rows exist.
      def hsk_level_label(level)
        scheme, number = level.split("-", 2)
        case scheme
        when "new" then "HSK #{number}"
        when "old" then "HSK 2.0 (#{number})"
        else level.humanize
        end
      end
    end
  end
end
