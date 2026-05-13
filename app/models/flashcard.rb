class Flashcard < ApplicationRecord
  validates :character, presence: true
  validates :pinyin, presence: true
  validates :meaning, presence: true
  validates :difficulty, presence: true

  before_validation :set_initial_review_time, on: :create

  private

  def set_initial_review_time
    self.next_review_at ||= Time.current
  end
end
