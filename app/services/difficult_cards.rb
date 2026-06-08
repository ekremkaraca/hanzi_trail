class DifficultCards
  DIFFICULT_RATINGS = %w[again hard].freeze

  def self.call(limit: 10)
    Flashcard
      .select("flashcards.*, COUNT(review_attempts.id) AS difficult_review_count")
      .joins(:review_attempts)
      .where(review_attempts: { rating: DIFFICULT_RATINGS })
      .group("flashcards.id")
      .order(Arel.sql("COUNT(review_attempts.id) DESC"))
      .limit(limit)
  end
end
