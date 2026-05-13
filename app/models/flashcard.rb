class Flashcard < ApplicationRecord
  DIFFICULTY_LEVELS = %w[new again easy good hard].freeze

  validates :character, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :meaning, presence: true
  validates :next_review_at, presence: true
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTY_LEVELS }
  validates :review_count, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_initial_review_time, on: :create

  private

  def set_initial_review_time
    self.next_review_at ||= Time.current
  end
end
