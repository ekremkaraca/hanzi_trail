module Review
  class Queue
    attr_reader :filters, :session

    def initialize(filters:, session:)
      @filters = filters
      @session = session
    end

    def next_card
      due_cards.first
    end

    def remaining_count
      due_cards.count
    end

    def empty_state_message
      # Keep service-level messaging available without changing the current view.
      return "No cards due!" if next_card.nil? && filters.empty?

      "No cards match your current filters."
    end

    def scope
      # Reuse the model scopes so queue filtering stays identical to the old controller.
      Flashcard
        .by_source(filters[:source])
        .by_category(filters[:category])
        .with_story_filter(filters[:story_status])
    end

    private

    def due_cards
      # DueFlashcards preserves the existing order and due-date cutoff behavior.
      @due_cards ||= DueFlashcards.call(scope:)
    end
  end
end
