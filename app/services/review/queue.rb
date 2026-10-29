module Review
  class Queue
    # Upper bound on the due cards a single page view reads. One bounded
    # query feeds both next_card and remaining_count, so the count can no
    # longer be an unbounded COUNT over the filtered due set: past the cap
    # remaining_count reports the cap (still exact below it, and the app's
    # whole table is far under it today).
    DUE_READ_CAP = 500

    attr_reader :filters, :session

    def initialize(filters:, session:)
      @filters = filters
      @session = session
    end

    def next_card
      due_page.first
    end

    def remaining_count
      due_page.size
    end

    def scope
      # Reuse the model scopes so queue filtering stays identical to the old controller.
      Flashcard
        .by_source(filters[:source])
        .by_hsk_level(filters[:hsk_level])
        .by_category(filters[:category])
        .with_story_filter(filters[:story_status])
    end

    private

    # One LIMIT read per queue instance, shared by next_card and
    # remaining_count. The old shape asked the database twice per page
    # view - a LIMIT 1 for the card and a separate full COUNT for the
    # number - and the COUNT had no bound at all.
    def due_page
      @due_page ||= DueFlashcards.call(scope:, new_cap:).limit(DUE_READ_CAP).to_a
    end

    # The 20/day cap paces casual review so new cards trickle in. An
    # explicit hsk_level filter is deliberate drilling — "I want HSK3
    # words now" — so the cap must not throttle it; unfiltered review
    # keeps the pacing.
    def new_cap
      filters[:hsk_level].present? ? nil : DueFlashcards::NEW_CARDS_PER_DAY
    end
  end
end
