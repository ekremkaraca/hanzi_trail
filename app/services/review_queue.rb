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
    @due_cards ||=scope.due_for_review
  end
end
