class ReviewQueue
  def initialize(scope: Flashcard.all)
    @scope = scope
  end

  def next_card
    due_cards.first
  end

  def remaining_count
    due_cards.count
  end

  private

  attr_reader :scope

  def due_cards
    scope
      .due_for_review
      .order(:next_review_at, :id)
  end
end
