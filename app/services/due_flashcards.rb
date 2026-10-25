class DueFlashcards
  # Daily ceiling on never-reviewed cards entering the queue. The importer's
  # date stagger spreads arrivals across months; this is the runtime governor
  # that keeps "today" a fixed-size choice no matter how much has accumulated
  # (bulk import, long break, many filters). Cards already in the SRS cycle
  # are never capped - repetitions must not be starved.
  NEW_CARDS_PER_DAY = 20

  def self.call(scope: Flashcard.all, new_cap: NEW_CARDS_PER_DAY)
    new(scope, new_cap).call
  end

  def initialize(scope, new_cap)
    @scope = scope
    @new_cap = new_cap
  end

  def call
    due = scope.due_for_review
    return due if new_cap.nil?

    # Reviewed cards pass freely; brand-new cards pass only within today's
    # remaining budget, oldest-due first (due_for_review's ordering).
    due.where(
      "flashcards.review_count > 0 OR flashcards.id IN (:admitted_new_ids)",
      admitted_new_ids: admitted_new_ids(due)
    )
  end

  private

  attr_reader :scope, :new_cap

  def admitted_new_ids(due)
    remaining = [ new_cap - introduced_today, 0 ].max
    return [] if remaining.zero?

    due.where(review_count: 0).limit(remaining).pluck(:id)
  end

  # New cards introduced today = cards whose only review so far happened
  # today (review_count == 1 with an attempt in today's local window).
  # Known edge: a card rated "again" twice today has review_count 2 and
  # stops counting, so the cap can leak by a few cards on heavy-again days
  # - acceptable for a governor, and it leaks toward MORE practice, not less.
  def introduced_today
    ReviewAttempt
      .where(reviewed_at: Date.current.all_day)
      .joins(:flashcard)
      .where(flashcards: { review_count: 1 })
      .distinct
      .count(:flashcard_id)
  end
end
