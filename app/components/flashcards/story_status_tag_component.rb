module Flashcards
  class StoryStatusTagComponent < ViewComponent::Base
    STATUSES = {
      "missing" => [ "Missing Story", "badge--warning" ],
      "draft"   => [ "Draft Story",   "badge--info" ],
      "curated" => [ "Curated Story", "badge--success" ]
    }.freeze
    DEFAULT  = [ "Unknown Story", "badge--neutral" ].freeze

    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard

    def label
      tuple.first
    end

    def css_class
      tuple.last
    end

    def tuple
      STATUSES.fetch(flashcard.story_status, DEFAULT)
    end
  end
end
