class ReviewAttempt < ApplicationRecord
  RATINGS = Flashcard::REVIEW_RATINGS

  belongs_to :flashcard

  validates :rating, presence: true, inclusion: { in: RATINGS }
  validates :reviewed_at, presence: true

  before_validation :set_reviewed_at, on: :create

  scope :recent, -> { order(reviewed_at: :desc) }
  scope :today, -> { where(reviewed_at: Time.current.all_day) }
  scope :by_rating, ->(rating) { where(rating: rating) }

  private

  def set_reviewed_at
    self.reviewed_at ||= Time.current
  end
end
