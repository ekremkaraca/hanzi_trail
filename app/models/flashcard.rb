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

  scope :by_source, ->(source) { source.present? ? where(source: source) : all }
  scope :by_hsk_level, ->(hsk_level) { hsk_level.present? ? where(hsk_level: hsk_level) : all }
  scope :by_category, ->(category) { category.present? ? where(category: category) : all }

  def schedule_next_review!(rating)
    raise ArgumentError, "Invalid rating" unless REVIEW_RATINGS.include?(rating)

    interval =
      case rating
      when "again" then 10.minutes
      when "hard" then 1.day
      when "good" then 3.days
      when "easy" then 7.days
      end

    with_lock do
      raise ActiveRecord::RecordNotFound unless next_review_at <= Time.current

      update!(
        difficulty: rating,
        review_count: review_count + 1,
        next_review_at: interval.from_now
      )
    end
  end

  private

  def set_initial_review_time
    self.next_review_at ||= Time.current
  end
end
