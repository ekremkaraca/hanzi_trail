class DifficultCards
  DIFFICULT_RATINGS = %w[again hard].freeze

  # Only recent struggles count: a card that was
  # fought with months ago but has since stuck
  # should not stay pinned as "difficult".
  DIFFICULT_WINDOW = 90.days

  def self.call(limit: 10)
    Flashcard
      .select("flashcards.*, COUNT(review_attempts.id) AS difficult_review_count")
      .joins(:review_attempts)
      .where(review_attempts: { rating: DIFFICULT_RATINGS })
      .where("review_attempts.reviewed_at > ?", DIFFICULT_WINDOW.ago)
      .group("flashcards.id")
      .order(Arel.sql("COUNT(review_attempts.id) DESC"))
      .limit(limit)
  end
end
