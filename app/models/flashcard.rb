class Flashcard < ApplicationRecord
  class CardNotDueError < StandardError; end

  DIFFICULTY_LEVELS = %w[new again easy good hard].freeze
  REVIEW_RATINGS = %w[again easy good hard].freeze
  SOURCES = %w[curated hsk].freeze
  STORY_STATUSES = %w[missing draft curated].freeze

  has_many :review_attempts, dependent: :destroy

  validates :character, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :meaning, presence: true
  validates :next_review_at, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTY_LEVELS }
  validates :story_status, presence: true, inclusion: { in: STORY_STATUSES }
  validates :review_count, numericality: { greater_than_or_equal_to: 0 }
  validates :meaning, length: { maximum: 500 }
  validates :story, length: { maximum: 2_000 }, allow_blank: true
  validates :components, length: { maximum: 1_000 }, allow_blank: true
  validates :literal_meaning, length: { maximum: 500 }, allow_blank: true
  validates :mnemonic, length: { maximum: 1_000 }, allow_blank: true
  validates :usage_note, length: { maximum: 1_000 }, allow_blank: true


  with_options on: :create do
    before_validation :set_initial_review_time
    before_validation :set_default_story_status
    before_validation :set_story_status_from_story
  end

  scope(:due_for_review, -> {
    where("next_review_at <= ?", Time.current).order(:next_review_at, :id)
  })

  scope :by_source, ->(source) { source.present? ? where(source: source) : all }
  scope :by_hsk_level, ->(hsk_level) { hsk_level.present? ? where(hsk_level: hsk_level) : all }
  scope :by_category, ->(category) { category.present? ? where(category: category) : all }
  scope :by_story_status, ->(story_status) { story_status.present? ? where(story_status: story_status) : all }

  scope :search, ->(query) {
    if query.present?
      where(
        "character ILIKE :query
        OR pinyin ILIKE :query
        OR meaning ILIKE :query
        OR category ILIKE :query",
        query: "%#{sanitize_sql_like(query)}%"
      )
    else
      all
    end
  }

  scope :missing_story, -> {
    where(story_status: "missing")
  }

  scope :draft_story, -> {
    where(story_status: "draft")
  }

  scope :curated_story, -> {
    where(story_status: "curated")
  }

  scope :short_story, -> {
    where.not(story: [ nil, "" ]).where("LENGTH(story) < ?", 80)
  }

  def schedule_next_review!(rating)
    raise ArgumentError, "Invalid rating" unless REVIEW_RATINGS.include?(rating)

    intervals = { "again" => 1.minute, "hard" => 1.day, "good" => 3.days, "easy" => 7.days }

    with_lock do
      raise CardNotDueError unless next_review_at <= Time.current

      update!(
        difficulty: rating,
        review_count: review_count + 1,
        next_review_at: intervals.fetch(rating).from_now
      )

      review_attempts.create!(
        rating: rating,
        reviewed_at: Time.current
      )
    end
  end

  def story_missing?
    story_status == "missing"
  end

  def story_draft?
    story_status == "draft"
  end

  def story_curated?
    story_status == "curated"
  end

  def short_story?
    # Under 80 chars is probably too short to be a useful mnemonic/story.
    story.to_s.length.positive? && story.to_s.length < 80
  end

  private

  def set_initial_review_time
    self.next_review_at ||= Time.current
  end

  def set_default_story_status
    if story.blank?
      self.story_status = "missing"
    elsif story_status.blank? || (story_status == "missing" && !will_save_change_to_story_status?)
      self.story_status = "curated"
    end
  end

  def set_story_status_from_story
    return if story_status.present? && !will_save_change_to_story?

    self.story_status = story.present? ? "curated" : "missing"
  end
end
