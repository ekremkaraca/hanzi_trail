class DueFlashcards
  def self.call(scope: Flashcard.all)
    new(scope).call
  end

  def initialize(scope)
    @scope = scope
  end

  def call
    scope.due_for_review
  end

  private

  attr_reader :scope
end
