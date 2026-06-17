module Flashcards
  class StoryStatusTagComponent < ViewComponent::Base
    STATUSES = {
      "missing" => [ "Missing Story", "is-warning" ],
      "draft"   => [ "Draft Story",   "is-info" ],
      "curated" => [ "Curated Story", "is-success" ]
    }.freeze
    DEFAULT  = [ "Unknown Story", "is-light" ].freeze

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
