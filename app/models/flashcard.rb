class Flashcard < ApplicationRecord
  DIFFICULTY_LEVELS = %w[new again easy good hard].freeze
  REVIEW_RATINGS = %w[again easy good hard].freeze

  validates :character, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :meaning, presence: true
  validates :next_review_at, presence: true
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTY_LEVELS }
  validates :review_count, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_initial_review_time, on: :create

  scope(:due_for_review, -> {
    where("next_review_at <= ?", Time.current).order(:next_review_at, :id)
  })

  def schedule_next_review!(rating)
    raise ArgumentError, "Invalid rating" unless REVIEW_RATINGS.include?(rating)

    interval =
      case rating
      when "again"
        10.minutes
      when "hard"
        1.day
      when "good"
        3.days
      when "easy"
        7.days
      end

    update!(
      difficulty: rating,
      review_count: review_count + 1,
      next_review_at: interval.from_now
    )
  end

  private

  def set_initial_review_time
    self.next_review_at ||= Time.current
  end
end
