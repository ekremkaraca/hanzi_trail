module Flashcards
  class EmptyStateComponent < ViewComponent::Base
    def initialize(story_status: nil)
      @story_status = story_status
    end

    private

    attr_reader :story_status

    def title
      case story_status
      when "draft"   then "No draft stories found."
      when "curated" then "No curated stories found."
      when "missing" then "No missing stories found."
      when "short"   then "No short stories found."
      else "No flashcards matched your filter."
      end
    end
  end
end
